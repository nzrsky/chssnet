# Go board recognition project
# Misc functions
# (c) kol, 2019-2023

import cv2
import numpy as np
import string as ss
from PIL import Image, ImageTk
from random import randint

from .grdef import *

def show(title, img):
    """Show an image and wait for key press"""
    cv2.imshow(title, img)
    cv2.waitKey()

def make_stones_img(shape, points, color = COLOR_BLACK, img = None):
    """ Draw stones on an image
        Parameters:
           shape   Image shape to generate
           points  Array of stone coordinates (X,Y,R)
           color   Stone color
           img     If not None, this image is used to plot stones (shape is ignored)
        Returns:
            An image
    """
    if img is None:
       img = np.full(shape, COLOR_WHITE[0], dtype=np.uint8)

    n = 0
    for p in points:
        x1 = p[0]
        y1 = p[1]
        r = p[2]
        if not type(color) is list:
            c = color
        else:
            if n >= len(color): n = 0
            c = color[n]
            n += 1
        cv2.circle(img, (x1,y1), r, c, -1)

    return img

# Show stones
# The function takes image shape and array of stone coordinates (X,Y,R)
# The function creates a new image with the same shape and draw the stones there
# If f_show = TRUE, image is been shown
def show_stones(title, shape, points, color = None, img = None):
    if points is None:
       return

    img = make_stones_img(shape, points, color, img)
    show(title, img)

# Make image displaying given lines
# If an image is provided, lines are drawn on it
# Otherwise it creates a new image with the same shape and draw the lines there
def make_lines_img(shape, lines, width = 1, color = COLOR_BLACK, img = None):
    if (img is None):
       img = np.full(shape, COLOR_WHITE[0], dtype=np.uint8)
    for i in lines:
        x1 = i[GR_FROM][GR_X]
        y1 = i[GR_FROM][GR_Y]
        x2 = i[GR_TO][GR_X]
        y2 = i[GR_TO][GR_Y]
        cv2.line(img, (x1,y1), (x2,y2), color, width)

    return img

# Show lines
# The function takes image shape and array of line coordinates (X1,Y1,X2,Y2)
# If an image is provided, lines are drawn on it
# Otherwise it creates a new image with the same shape and draw the lines there
def show_lines(title, shape, lines, img = None):
    img = make_lines_img(shape, lines, img)
    show(title, img)

# Convert CV2 image to Tkinter format
def img_to_imgtk(img):
    """ Convert OpenCV image to PIL PhotoImage"""
    if img is None:
       return None

    if len(img.shape) ==3 and img.shape[2] == 3:
        b,g,r = cv2.split(img)
        img = cv2.merge((r,g,b))
    imgtk = ImageTk.PhotoImage(image=Image.fromarray(img))
    return imgtk

def unique_rows(a):
    """Elmininates duplicates in 1D-rray"""
    a = np.ascontiguousarray(a)
    unique_a = np.unique(a.view([('', a.dtype)]*a.shape[1]))
    return unique_a.view(a.dtype).reshape((unique_a.shape[0], a.shape[1]))

def img1_to_img3(img):
    """ Convert 1-channel (BW) image to 3-channel"""
    if img is None:
       return None
    if len(img.shape) > 2:
       raise ValueError('Image is not 1-channel')

    img3 = np.empty((img.shape[0], img.shape[1], 3), dtype=np.uint8)
    for i in range(3): img3[:,:,i] = img
    return img3

def format_stone_pos(stone, axis = None):
    if stone is None:
        return ''
    if stone[GR_A] > 30 or stone[GR_B] > 30 or stone[GR_A] <= 0 or stone[GR_B] <= 0:
        return 'XX'
    elif axis is None:
        return ss.ascii_uppercase[stone[GR_A]-1] + str(stone[GR_B])
    elif axis == GR_A:
        return ss.ascii_uppercase[stone[GR_A]-1]
    elif axis == GR_B:
        return str(stone[GR_B])
    else:
        return int(round(stone[axis],0))

def stone_pos_from_str(pos):
    if pos is None:
        return (None, None)
    ps = str(pos).upper()
    a = ord(ps[0]) - ord('A') + 1
    if a < 0:
        raise ValueError("Invalid stone position " + ps)
    try:
        b = int(ps[1:])
    except:
        raise ValueError("Invalid stone position " + ps)
    return (a, b)

def gres_to_jgf(res):
    """Converts board recognition results to JGF dictionary"""
    def sp(stones):
        p = dict()
        for stone in stones:
            key = format_stone_pos(stone)
            p[key] = dict()
            p[key]['X'] = format_stone_pos(stone, GR_X)
            p[key]['Y'] = format_stone_pos(stone, GR_Y)
            p[key]['R'] = format_stone_pos(stone, GR_R)
            p[key]['A'] = format_stone_pos(stone, GR_A)
            p[key]['B'] = format_stone_pos(stone, GR_B)
        return p

    jgf = dict()
    jgf['board_size'] = res[GR_BOARD_SIZE]
    jgf['edges'] = dict()
    jgf['edges']['0'] = res[GR_EDGES][0]
    jgf['edges']['1'] = res[GR_EDGES][1]
    jgf['spacing'] = res[GR_SPACING]
    jgf['num_stones'] = (len(res[GR_STONES_B]), len(res[GR_STONES_W]))
    jgf['black'] = sp(res[GR_STONES_B])
    jgf['white'] = sp(res[GR_STONES_W])
    return jgf

def jgf_to_gres(jgf):
    """Converts JGF dictionary to board recognition results"""
    def sp(stones):
        p = np.zeros((len(stones), 5), dtype = np.int32)
        n = 0
        for key in stones.keys():
            stone = stones[key]
            p[n,GR_X] = int(stone['X'])
            p[n,GR_Y] = int(stone['Y'])
            p[n,GR_R] = int(stone['R'])
            p[n,GR_A] = ord(stone['A']) - ord('A') + 1
            p[n,GR_B] = int(stone['B'])
            n += 1
        return p

    res = dict()
    res[GR_BOARD_SIZE] = jgf['board_size']
    res[GR_EDGES] = [(0,0),(0,0)]
    res[GR_EDGES][0] = jgf['edges']['0']
    res[GR_EDGES][1] = jgf['edges']['1']
    res[GR_SPACING] = jgf['spacing']
    res[GR_STONES_B] = sp(jgf['black'])
    res[GR_STONES_W] = sp(jgf['white'])
    return res

def resize(img, new_size=None, scale=None, f_upsize=True, f_center=False, pad_color=(255, 255, 255)):
    """Resizes an image so neither of its sides will be bigger that max_size saving proportions.
    See resize3 for paramaters definition.

    Returns:
        Resized image
    """
    im = resize3(img, new_size, scale, f_upsize, f_center, pad_color)[0]
    return im

def resize2(img, new_size=None, scale=None, f_upsize=True, f_center=False, pad_color=(255, 255, 255)):
    """Resizes an image so neither of its sides will be bigger that max_size saving proportions.
    See resize3 for paramaters definition.

    Returns:
        Resized image
        Scale [scale_x, scale_y]. Scale < 1 means image was downsized
    """
    im, scale, _ = resize3(img, new_size, scale, f_upsize, f_center, pad_color)
    return im, scale

def resize3(img, new_size=None, scale=None, f_upsize=True, f_center=False, pad_color=(255, 255, 255)):
    """Resizes an image either to specified scale or to specified size.
    In case of resizing to max_size, neither of resulting image sides will be bigger than that.

    Parameters:
        img         An OpenCv image
        new_size    If is a tuple or list with 2 elements and both > 0, specifies target image size (width, height).
                    If one of elements is zero or a scalar value provided,
                    image is resized proportionally with `new_size`
                    specfying a maximum size of biggest image side.
        scale       Scale to resize to. Treated like `new_size`.
        f_upsize    If True, images with size less than max_size will be upsized
        f_center    If True, smaller images will be centered on bigger image with padding
        pad_color   Padding color

    Returns:
        Resized image
        Scale [scale_x, scale_y]. Scale < 1 means image was downsized
        Offset [x, y]. If image was centered, offset of image location
    """
    def center_image(img, new_size, pad_color):
        """Make a bigger image and center initial image on it"""
        if len(img.shape) > 2:
            im = np.full((new_size[0], new_size[1], img.shape[2]), pad_color, dtype=img.dtype)
        else:
            c = pad_color[0] if type(pad_color) is tuple else pad_color
            im = np.full((new_size[0], new_size[1]), c, dtype=img.dtype)

        h, w = img.shape[:2]
        dx, dy = int((new_size[1] - w)/2), int((new_size[0] - h)/2)

        im[dy:dy + h, dx:dx + w] = img
        return im, [dx, dy]

    if new_size is None and scale is None:
        raise ValueError("Either new_size or scale has to be provided")

    if scale is not None:
        # Resizing by scale
        if isinstance(scale, (list, tuple, np.ndarray)):
            im_scale = scale[0]
        else:
            im_scale = scale

        im = cv2.resize(img, dsize = None, fx = im_scale, fy = im_scale)
        img_size = int(np.max(im.shape[0:2]))
        if new_size is not None and img_size < new_size and f_center:
            return center_image(im, new_size, pad_color, im_scale)
        else:
            return im, [im_scale, im_scale], [0, 0]

    else:
        # Resizing to new_size
        if isinstance(new_size, (list, tuple, np.ndarray)):
            # Check size vector
            if len(new_size) < 2:
                new_size = new_size[0]
            else:
                new_size = new_size[:2]
                if new_size[0] is None or new_size[0] == 0:
                    new_size = new_size[0]
                elif new_size[1] is None or new_size[1] == 0:
                    new_size = new_size[1]

        if isinstance(new_size, (list, tuple, np.ndarray)):
            # Size vector provided
            h, w = img.shape[:2]
            im_scale = [new_size[0] / w, new_size[1] / h]
        else:
            # Only max size given
            im_size_max = np.max(img.shape[:2])
            im_size_min = np.min(img.shape[:2])
            im_scale = float(new_size) / float(im_size_min)

            if np.round(im_scale * im_size_max) > new_size:
                im_scale = float(new_size) / float(im_size_max)

            new_size = [new_size, new_size]
            im_scale = [im_scale, im_scale]

        if not f_upsize and min(im_scale) > 1.0:
           # Image size is less than new_size and upsize not allowed
           if not f_center:
              # Nothing to do!
              return img, [1.0, 1.0], [0, 0]
           else:
              # Make a bigger image and center source image on it
              im, ofs = center_image(img, new_size, pad_color)
              return im, im_scale, ofs
        else:
           # Perform normal resize
           im = cv2.resize(img, dsize=None, fx=im_scale[0], fy=im_scale[1])
           return im, im_scale, [0, 0]

def get_image_area(img, r):
    """Get part of an image defined by rectangular area.

    Parameters:
        img      An OpenCv image
        r        Area to extract (list or tuple [x1,y1,x2,y2])

    Returns:
        Extracted area
    """
    if r[0] < 0 or r[1] < 0:
       raise ValueError('Invalid area origin: {}'.format(r))
    dx = r[2] - r[0]
    dy = r[3] - r[1]
    if dx <= 0 or dy <= 0:
       raise ValueError('Invalid area length: {}'.format(r))

    im = None
    if len(img.shape) > 2:
       im = np.empty((dy, dx, img.shape[2]), dtype=img.dtype)
    else:
       im = np.empty((dy, dx), dtype=img.dtype)

    im[:] = img[r[1]:r[3], r[0]:r[2]]
    return im

def is_on(a, b, c):
    """Return true if point c is exactly on the line from a to b"""

    def collinear(a, b, c):
        "Return true iff a, b, and c all lie on the same line."
        return (b[0] - a[0]) * (c[1] - a[1]) == (c[0] - a[0]) * (b[1] - a[1])

    def within(p, q, r):
        "Return true iff q is between p and r (inclusive)."
        return p <= q <= r or r <= q <= p

    # (or the degenerate case that all 3 points are coincident)
    return (collinear(a, b, c)
            and (within(a[0], c[0], b[0]) if a[0] != b[0] else
                 within(a[1], c[1], b[1])))

def is_on_w(a,b,c,delta=1):
    """Return true if point c is on a line from a to b with some gap provided"""
    for i in range(delta*3):
        x = c[0] + i - 1
        for j in range(delta*3):
            y = c[1] + j - 1
            if is_on(a, b, (x, y)): return True
    return False


def random_colors(n):
    """Returns n random colors"""
    ret = []
    for i in range(n):
        r = randint(0,255)
        g = randint(0,255)
        b = randint(0,255)
        ret.extend([(r,g,b)])
    return ret

# Find value in a dictionary
# Based on https://stackoverflow.com/questions/8023306/get-key-by-value-in-dictionary
def dict_value2key(mydict, value):
    """Returns a key for given value or None"""
    if mydict is None:
        return None
    else:
        try:
            return list(mydict.keys())[list(mydict.values()).index(value)]
        except ValueError:
            return None

# Calculate board spacing
def board_spacing(edges, size):
    """Calculate board spacing"""
    space_x = (edges[1][0] - edges[0][0]) / float(size-1)
    space_y = (edges[1][1] - edges[0][1]) / float(size-1)
    return space_x, space_y


# Origin: imutils.rotate_bound
# author:    Adrian Rosebrock
# website:   http://www.pyimagesearch.com
def rotate(image, angle, fill_val = (0,0,0), keep_image = True):
    """Rotate given image to specified angle"""

    # grab the dimensions of the image and then determine the
    # center
    (h, w) = image.shape[:2]
    (cX, cY) = (w / 2, h / 2)

    # grab the rotation matrix (applying the negative of the
    # angle to rotate clockwise), then grab the sine and cosine
    # (i.e., the rotation components of the matrix)
    M = cv2.getRotationMatrix2D((cX, cY), -angle, 1.0)
    cos = np.abs(M[0, 0])
    sin = np.abs(M[0, 1])

    if not keep_image:
        # simple rotation with no care of image clipping
        nW = w
        nH = h
    else:
        # avoid clipping
        # compute the new bounding dimensions of the image
        nW = int((h * sin) + (w * cos))
        nH = int((h * cos) + (w * sin))

        # adjust the rotation matrix to take into account translation
        M[0, 2] += (nW / 2) - cX
        M[1, 2] += (nH / 2) - cY

    # perform the actual rotation and return the image
    return cv2.warpAffine(image, M, (nW, nH),
                          borderMode = cv2.BORDER_CONSTANT,
                          borderValue = fill_val)



