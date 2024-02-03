import sys
import os
import subprocess
import cv2
import numpy as np
from PIL import Image
import shutil
import re
import fitz
from tqdm import tqdm
from PIL import ImageOps

def get_terminal_width():
    return shutil.get_terminal_size().columns

def format_description(description, total_width):
    max_length = total_width // 2 - len('...')
    return (description[:max_length] + '...') if len(description) > max_length else description.ljust(max_length)

def aspect_fit_and_pad(image, target_size=(1634,2539)):
    """
    Resizes the image to fit the target size while maintaining aspect ratio.
    Adds white padding to fill any remaining space.
    """
    original_width, original_height = image.size
    target_width, target_height = target_size

    if original_width > original_height:
        middle = original_width // 2
        left_half = image.crop((0, 0, middle, original_height))
        right_half = image.crop((middle, 0, original_width, original_height))
        return [aspect_fit_and_pad(left_half)[0], aspect_fit_and_pad(right_half)[0]]
    elif original_width < target_width:
        new_image = Image.new("RGB", target_size, "white")
        y = (target_height - original_height) // 2
        x = (target_width - original_width) // 2
        new_image.paste(image, (x, y))
        return [new_image]
    else:
        ratio = target_width / float(original_width)
        new_size = (target_width, int(original_height * ratio))
        image = image.resize(new_size, Image.Resampling.LANCZOS)
        new_image = Image.new("RGB", target_size, "white")
        y = (target_height - new_size[1]) // 2
        new_image.paste(image, (0, y))
        return [new_image]

def convert_pdf_to_images(pdf_path, total_width):
    doc = fitz.open(pdf_path)
    images = []
    for i in tqdm(range(len(doc)), desc=format_description(f"Processing {os.path.basename(pdf_path)}", total_width), leave=True):
        page = doc.load_page(i)
        zoom = 2 
        mat = fitz.Matrix(zoom, zoom)
        pix = page.get_pixmap(matrix = mat,dpi=500)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        images.append(img)
    return images

def convert_djvu_to_images(djvu_path, temp_folder, total_width):
    output_format = os.path.join(temp_folder, 'page-%d.tiff')
    subprocess.run(["ddjvu", "-format=tiff", "-quality=100", "-mode=color", djvu_path, output_format], check=True)
    images = []
    file_list = sorted([f for f in os.listdir(temp_folder) if f.endswith('.tiff')])
    for filename in tqdm(file_list, desc=format_description(f"Processing {os.path.basename(djvu_path)}", total_width), leave=True):
        image_path = os.path.join(temp_folder, filename)
        images.append(Image.open(image_path))
    return images

def snake_case_name(name):
    name = re.sub(r'\W+', '_', name)
    return name.lower()

def process_file(file_path, output_root, total_width):
    file_name = os.path.splitext(os.path.basename(file_path))[0]
    output_folder = os.path.join(output_root, snake_case_name(file_name))
    os.makedirs(output_folder, exist_ok=True)

    is_pdf = file_path.lower().endswith('.pdf')
    if is_pdf:
        pages = convert_pdf_to_images(file_path, total_width)
    else:
        temp_folder = "temp_djvu"
        os.makedirs(temp_folder, exist_ok=True)
        pages = convert_djvu_to_images(file_path, temp_folder, total_width)

    for i, page in enumerate(tqdm(pages, desc=format_description(f"Extracting from {os.path.basename(file_path)}", total_width), leave=True)):
        open_cv_image = np.array(page)
        open_cv_image = open_cv_image[:, :, ::-1].copy()

        processed_images = aspect_fit_and_pad(Image.fromarray(open_cv_image))
        for j, img in enumerate(processed_images):
            tiff_filename = os.path.join(output_folder, f"page_{i + 1:02d}_{j}.png")
            img.save(tiff_filename,"PNG")

    if not is_pdf:
        shutil.rmtree(temp_folder)

def find_files(directory, extensions):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(extensions):
                yield os.path.join(root, file)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <path_to_directory>")
    else:
        directory = sys.argv[1]
        output_root = "./output"
        os.makedirs(output_root, exist_ok=True)
        terminal_width = get_terminal_width()

        total_files = sum(1 for _ in find_files(directory, ('.pdf', '.djvu')))
        file_progress = tqdm(find_files(directory, ('.pdf', '.djvu')), total=total_files, desc=format_description("Overall Progress", terminal_width), leave=True)

        for file_path in file_progress:
            process_file(file_path, output_root, terminal_width)
