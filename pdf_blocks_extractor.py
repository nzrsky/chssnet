import sys
import os
import subprocess
import cv2
import numpy as np
from PIL import Image, ImageOps
import shutil
import re
import fitz
from tqdm import tqdm
import argparse

def get_terminal_width():
    return shutil.get_terminal_size().columns

def format_description(description, total_width):
    max_length = total_width // 2 - len('...')
    return (description[:max_length] + '...') if len(description) > max_length else description.ljust(max_length)

def aspect_fit_and_pad(image, target_size):
    original_size = image.size
    ratio = min(target_size[i] / original_size[i] for i in range(2))
    new_size = tuple(int(original_size[i] * ratio) for i in range(2))
    image = image.resize(new_size, Image.Resampling.LANCZOS)
    new_image = Image.new("RGB", target_size, "white")
    new_image.paste(image, ((target_size[0] - new_size[0]) // 2, (target_size[1] - new_size[1]) // 2))
    return new_image

def rect_intersects(rectA, rectB):
    ax1, ay1, aw, ah = rectA
    bx1, by1, bw, bh = rectB
    ax2, ay2 = ax1 + aw, ay1 + ah
    bx2, by2 = bx1 + bw, by1 + bh

    if ax1 >= bx2 or bx1 >= ax2:
        return False
    if ay1 >= by2 or by1 >= ay2:
        return False
    return True

def extract_rectangles_from_page(page, zoom=2, dpi=500, min_size=100, min_aspect=0.5, max_aspect=2):
    zoom = dpi / 72

    # Render the page to a pixmap at the specified zoom level.
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)

    # Convert the pixmap to a PIL image for processing.
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

    # Convert the PIL image to an OpenCV image.
    open_cv_image = np.array(img)
    open_cv_image = cv2.cvtColor(open_cv_image, cv2.COLOR_RGB2BGR)

    # Preprocess the image for contour detection.
    gray = cv2.cvtColor(open_cv_image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edged = cv2.Canny(blurred, 75, 200)
    contours, _ = cv2.findContours(edged.copy(), cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    rectangles = []
    for c in contours:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            x, y, w, h = cv2.boundingRect(approx)
            if max(w, h) > min_size and min_aspect < (w / h) < max_aspect:
                rectangles.append((x, y, w, h))

    filtered_rects = []
    for i, rectA in enumerate(rectangles):
        keep = True
        for j, rectB in enumerate(filtered_rects):
            if rect_intersects(rectA, rectB):
                keep = False
                break
        if keep:
            filtered_rects.append(rectA)

    filtered_rect_images = []
    for rect in filtered_rects:
        x, y, w, h = rect
        rect_img = open_cv_image[y:y+h, x:x+w]
        rect_img_pil = Image.fromarray(cv2.cvtColor(rect_img, cv2.COLOR_BGR2RGB))
        filtered_rect_images.append(rect_img_pil)

    return filtered_rect_images

def snake_case_name(name):
    name = re.sub(r'\W+', '_', name)
    return name.lower()

def process_file(file_path, output_folder, target_size, total_width, min_size):
    file_name = os.path.splitext(os.path.basename(file_path))[0]
    output_subfolder = os.path.join(output_folder, snake_case_name(file_name))
    os.makedirs(output_subfolder, exist_ok=True)

    doc = fitz.open(file_path)
    for i, page in enumerate(tqdm(doc, desc=format_description(f"Extracting from {os.path.basename(file_path)}", total_width), leave=True)):
        rectangles = extract_rectangles_from_page(page, min_size=min_size)
        for j, rect_img in enumerate(rectangles):
            fitted_image = aspect_fit_and_pad(rect_img, target_size)
            image_filename = os.path.join(output_subfolder, f"rect_{i + 1:02d}_{j}.png")
            fitted_image.save(image_filename, "PNG")

def find_files(directory, extensions):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(extensions):
                yield os.path.join(root, file)

def main():
    parser = argparse.ArgumentParser(description="Extract rectangles from PDF and DJVU files.")
    parser.add_argument("directory", help="Directory containing the files to process.")
    parser.add_argument("-o", "--output", default="./output_images", help="Output directory for extracted images.")
    parser.add_argument("-s", "--size", default=224, type=int, help="Size of the output square images.")
    parser.add_argument("-m", "--minrectsize", default=100, type=int, help="Min size to detect")
    args = parser.parse_args()

    directory = args.directory
    output_root = args.output
    image_size = (args.size, args.size)
    min_size = args.minrectsize
    os.makedirs(output_root, exist_ok=True)
    terminal_width = get_terminal_width()

    total_files = sum(1 for _ in find_files(directory, ('.pdf', '.djvu')))
    file_progress = tqdm(find_files(directory, ('.pdf', '.djvu')), total=total_files, desc=format_description("Overall Progress", terminal_width), leave=True)

    for file_path in file_progress:
        process_file(file_path, output_root, image_size, terminal_width, min_size=min_size)

if __name__ == "__main__":
    main()
