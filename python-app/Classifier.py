import torch
from torchvision import transforms
from PIL import Image
import os
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import matplotlib.pyplot as plt
from tqdm import tqdm
from torch.optim.lr_scheduler import StepLR
from PIL import Image
from matplotlib import cm
import cv2

transform = transforms.Compose([
    #transforms.Grayscale(),
     #transforms.RandomHorizontalFlip(),   # Randomly flip the image horizontally
    #transforms.RandomRotation(15),       # Randomly rotate the image by a maximum of 10 degrees
     #transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1), # Adjust color jitter
    # transforms.RandomAffine(degrees=0, translate=(0.1, 0.1), scale=(0.9, 1.1)), # Random affine transformation
    #transforms.RandomResizedCrop(32, scale=(0.8, 1.0), ratio=(0.9, 1.1)),  # Random resized crop
    transforms.ToTensor(),              # Convert the image to a PyTorch tensor
     transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalize the image
])


transformFlip = transforms.Compose([
    #transforms.Grayscale(),
     transforms.RandomHorizontalFlip(p=2),   # Randomly flip the image horizontally
    #transforms.RandomRotation(15),       # Randomly rotate the image by a maximum of 10 degrees
     #transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1), # Adjust color jitter
    # transforms.RandomAffine(degrees=0, translate=(0.1, 0.1), scale=(0.9, 1.1)), # Random affine transformation
    #transforms.RandomResizedCrop(32, scale=(0.8, 1.0), ratio=(0.9, 1.1)),  # Random resized crop
    transforms.ToTensor(),              # Convert the image to a PyTorch tensor
     transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])  # Normalize the image
])






# Function to classify images in a folder
def classify_images(filenname,model,device):
    for i in range(filenname.shape[0]):
        for j in range(filenname.shape[1]):

            if filenname[i][j][2] > 100 and filenname[i][j][1] < 60 and filenname[i][j][0] < 60:


                filenname[i][j][0] = 255
                filenname[i][j][1] = 0
                filenname[i][j][2] = 0
                # print("im", filenname[i][j])


    model.eval()


                #print("im", filenname[i][j])





    results = {}
    #PIL_image1 = Image.fromarray(np.uint8(filenname)).conver('RGB')

    PIL_image1 = Image.fromarray(filenname.astype('uint8'))
    PIL_image2 = Image.fromarray(filenname.astype('uint8'))


    #PIL_image1.show()

    #Image.fromarray(np.uint8(cm.gist_earth(filenname) * 255))
    #image = Image.open(filenname).convert('RGB')


    #print(type(rgb_image))

    #image.show()
    #image = Image.open(image).convert('RGB')

    image1 = transform(PIL_image1).unsqueeze(0)  # Add batch dimension




    image1= image1.to(device)
    output1 = model(image1)
    Pro1, predicted1 = torch.max(output1, 1)

    image2 = transformFlip(PIL_image2).unsqueeze(0)  # Add batch dimension

    image2 = image2.to(device)
    output2 = model(image2)
    Pro2, predicted2 = torch.max(output2, 1)
    if (Pro1 > Pro2):
        predicted = predicted1
    else:
        predicted = predicted2
    print(Pro1, Pro2)
    print(predicted1.item(), predicted2.item())

    results = predicted.item()
    print("Result",results)

    return results


# Define the device

# Path to the folder containing images

# Load the model and classify images

# Print results


