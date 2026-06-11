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



class FMNIST_Net2(nn.Module):
    def __init__(self, num_classes):
        super(FMNIST_Net2, self).__init__()
        self.conv1 = nn.Conv2d(3, 32, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.dropout1 = nn.Dropout(0.5)
        self.dropout2 = nn.Dropout(0.25)
        self.fc1 = nn.Linear(2 * 320000, 128)  # Adjust input features based on your image size after conv layers
        self.fc2 = nn.Linear(128, num_classes)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        return x


# Load the saved model
def load_checkpoint(filepath):

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Device: ", device)
    checkpoint = torch.load(filepath, map_location=device)
    model = FMNIST_Net2(num_classes=2)  # Replace with your model class and number of classes
    model.load_state_dict(checkpoint['model_state_dict'])
    model.to(device)  # Ensure the model is moved to the correct device
    model.eval()  # Set the model to evaluation mode
    return model

