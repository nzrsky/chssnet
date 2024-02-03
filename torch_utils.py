from unittest import result
import torch
import subprocess

def get_best_device() -> torch.device:
    print("Picking best device...")

    try:
        import torch_xla
        import torch_xla.core.xla_model as xm
        # from torch_xla.distributed.parallel_loader import ParallelLoader  # Uncomment if you use ParallelLoader

        print("✅ TPU is available")
        return xm.xla_device()
        
    except ImportError:
        print("❎ TPU is not available")

        if torch.cuda.is_available():
            print('✅ Cuda GPU is available')
            print(subprocess.run(['nvidia-smi'], stdout=subprocess.PIPE, text=True).stdout)
            return torch.device('cuda')            
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            print("❎ Cuda GPU is not available")
            print('✅ MPS (Apple Silicon) GPU is available')
            return torch.device('mps')
        else:
            print("❎ Cuda GPU is not available")
            print('❎ MPS (Apple Silicon) GPU is available')
            return torch.device('cpu')
        

def to_device(data, device: torch.device):
    """Move tensor(s) to chosen device"""
    if isinstance(data, (list, tuple)):
        return [to_device(x, device) for x in data]
    return data.to(device, non_blocking=True)


def empty_cache():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
        torch.mps.empty_cache()
    torch.cuda.ipc_collect()


# ---------------------------------------------------

import random
import os
import numpy as np

def seed_everything(seed: int = 1984) -> int:
    def seed_basic(seed: int):
        random.seed(seed)
        os.environ['PYTHONHASHSEED'] = str(seed)
        np.random.seed(seed)
        
    def seed_torch(seed: int):
        torch.manual_seed(seed)
        if torch.cuda.is_available():
            torch.cuda.manual_seed(seed)
            torch.cuda.manual_seed_all(seed)
        if torch.backends.mps.is_available():
            torch.mps.manual_seed(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False

    seed_basic(seed)
    seed_torch(seed)

    return seed

# ---------------------------------------------------

from torchvision.transforms.functional import to_tensor, to_pil_image
from PIL import Image
import torch
import numpy as np

def pil_to_tensor(image: Image.Image|list[Image.Image]) -> torch.Tensor:
    """
    Convert a PIL Image or a list of PIL Images to a PyTorch tensor.
    """
    if isinstance(image, Image.Image):
        return to_tensor(image).unsqueeze(0) 
    elif isinstance(image, list):
        return torch.stack([to_tensor(img) for img in image])
    else:
        raise TypeError("Input must be a PIL Image or a list of PIL Images.")


def tensor_to_pil(tensor: torch.Tensor) -> Image.Image | list[Image.Image]:
    """
    Convert a PyTorch tensor to a PIL Image or a list of PIL Images.
    """
    if tensor.ndim == 4: 
        return [to_pil_image(img) for img in tensor]
    elif tensor.ndim == 3: 
        return to_pil_image(tensor)
    else:
        raise ValueError("Tensor dimension must be 3 (C, H, W) for single image or 4 (B, C, H, W) for a batch of images.")


def numpy_to_tensor(array: np.ndarray) -> torch.Tensor:
    """
    Convert a NumPy array or a list of NumPy arrays to a PyTorch tensor.
    """
    assert(isinstance(array, np.ndarray))

    if array.ndim == 3:
        return torch.from_numpy(array).permute(2, 0, 1).unsqueeze(0).float()
    elif array.ndim == 4: 
        return torch.from_numpy(array).permute(0, 3, 1, 2).float()
    else:
        raise TypeError("Input must be a NumPy array with 3 (H, W, C) dimensions for a single image or 4 (B, H, W, C) for a batch of images.")


def tensor_to_numpy(tensor: torch.Tensor) -> np.ndarray:
    """
    Convert a PyTorch tensor to a NumPy array or a list of NumPy arrays.
    """
    tensor = tensor.detach().cpu()
    if tensor.ndim == 4:
        return tensor.permute(0, 2, 3, 1).numpy()
    elif tensor.ndim == 3:
        return tensor.permute(1, 2, 0).numpy()
    else:
        raise ValueError("Tensor dimension must be 3 (C, H, W) for single image or 4 (B, C, H, W) for a batch of images.")
    

def numpy_to_pil(image: np.ndarray) -> Image.Image:
    assert(isinstance(image, np.ndarray))
    return Image.fromarray(image)


def pil_to_numpy(image: Image.Image):
    assert(isinstance(image, Image.Image))
    return np.array(image)
    

import matplotlib.pyplot as plt
import matplotlib.patches as patches

def __image_sample(images) -> Image.Image:
    if isinstance(images, torch.Tensor):
        result = tensor_to_pil(images[0])
        return result[0] if isinstance(result, list) else result
    elif isinstance(images, np.ndarray):
        return numpy_to_pil(images[0])
    elif isinstance(images, Image.Image): 
        return images
    elif isinstance(images, list):
        return images[0]
    else: 
        raise ValueError("image is not in PIL format")

def __label_sample(labels) -> int:
    if isinstance(labels, (list, torch.Tensor, np.ndarray)):
        return labels[0] if isinstance(labels, (list, np.ndarray)) else int(labels[0].item())
    else:
        return labels[0]

def plot_labeled_images(dataloader, title="", num_images=5, class_labels:dict[int, str]={}):
    fig, axes = plt.subplots(1, num_images, figsize=(num_images * 5, 5))
    
    if num_images == 1:
        axes = [axes]

    for i, (images, labels) in enumerate(dataloader):
        if i >= num_images:
            break

        ax = axes[i]
        
        image = __image_sample(images)
        ax.imshow(image)
        ax.set_xticks([])
        ax.set_yticks([])

        label = __label_sample(labels)
        ax.set_title(class_labels.get(int(label), f"{label}"), y=-0.15)

    fig.suptitle(title)
    plt.tight_layout(rect=(0.0, 0.0, 1.0, 0.95))
    plt.show()

def plot_labeled_bboxed_images(dataloader, title="", num_images=5, class_labels:dict[int, str]={}):
    
    fig, axes = plt.subplots(1, num_images, figsize=(num_images * 5, 5))
    
    if num_images == 1:
        axes = [axes]

    for i, (images, targets) in enumerate(dataloader):
        if i >= num_images:
            break

        ax = axes[i]
        
        image = __image_sample(images)
        ax.imshow(image)
        ax.set_xticks([])
        ax.set_yticks([])

        w, h = image.size
        # ax.set_xlim(0, w)
        # ax.set_ylim(0, h)

        labels_count = len(targets['labels'][0])

        for i in range(labels_count):
            bbox = targets['boxes'][0][i]
            label = targets['labels'][0][i]
            rect = patches.Rectangle(
                (bbox[0], bbox[1]), 
                bbox[2], bbox[3], 
                linewidth=2, 
                edgecolor='r', 
                facecolor='none'
            )
            ax.add_patch(rect)

            text = class_labels.get(int(label), f"{label}")
            text_x = bbox[0] + rect.get_linewidth()
            text_y = bbox[1] + rect.get_linewidth()
            ax.text(text_x, text_y, text, verticalalignment='top', 
                color='white', fontsize=12, weight='bold', 
                bbox=dict(facecolor='red', alpha=0.5, edgecolor='red'))

    fig.suptitle(title)
    plt.tight_layout(rect=(0.0, 0.0, 1.0, 0.95))
    plt.show()

# ---------------------------------------------------

from PIL import Image, ImageOps

class ResizeAndPad(object):
    def __init__(self, output_size:tuple[int,int], fill:tuple[int,int,int]=(255,255,255)):
        self.output_size = output_size
        self.fill = fill

    def __call__(self, img):
        img = ImageOps.pad(img, self.output_size, method=Image.Resampling.LANCZOS, color=self.fill)
        return img