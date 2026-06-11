# -*- coding: utf-8 -*-
"""
Created on Tue Jan 30 13:48:07
 2024

@author: Juan Carlos
"""


# Define the directory for the virtual environment

import os
import shutil
from Classifier import classify_images
from PIL import Image
import cv2
import mediapipe as mp
import time
import numpy as np
import matplotlib.pyplot as plt
import socket
from time import sleep
from threading import Thread
import torch
from torchvision import transforms
from threading import Event
import os
import imutils
# from net import FMNIST_Net2
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import random
import tkinter as tk
from screeninfo import get_monitors
from plot_cycls2 import Plot
message = ''
TotalCycles = 0
Num_semi = 0
iscodeanalusisrun = False
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
#from Salman1 import classify
from datetime import datetime
Quitting = False
currentTime = 0
normX = 0
normY = 0
monitors = get_monitors()

from LoadModel import load_checkpoint



if len(monitors)>1:
    second_monitor = monitors[1]
else:
    second_monitor = monitors[0]

previousValue = False
source_dir = "DetectedCycles/"

if os.path.exists(source_dir):
    shutil.rmtree(source_dir)
    print(f"Deleted directory: {source_dir}")
    os.makedirs(source_dir)
    print(f"Directory does not exist: {source_dir}")
else:
    os.makedirs(source_dir)
    print(f"Directory does not exist: {source_dir}")
    print(f"Directory does not exist: {source_dir}")

flag = False
# %%
# Load your model or object with map_location set to 'cpu'
#
# model_path = r"model_best_checkpoint2.pth.tar"
# model = torch.load(model_path, map_location=torch.device('cpu'))
#
# model = FMNIST_Net2(4)
# checkpoint = torch.load(model_path)
# model.load_state_dict(checkpoint['model'])
# #model = checkpoint['model']
# device = torch.device('cuda')
# model_device = torch.device('cuda')
# #model_gpu = model.to("cuda")
# device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
# model.to(device)
# %%
WristCoordinates = []
Num_loggings = []
# MediaPipe 0.10+ nouvelle API
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
from mediapipe.tasks.python.vision import HandLandmarkerOptions, HandLandmarker

# Compatibilité : on recrée un objet mp_hands avec les constantes nécessaires
class _FakeHands:
    HAND_CONNECTIONS = [
        (0,1),(1,2),(2,3),(3,4),
        (0,5),(5,6),(6,7),(7,8),
        (5,9),(9,10),(10,11),(11,12),
        (9,13),(13,14),(14,15),(15,16),
        (13,17),(17,18),(18,19),(19,20),
        (0,17)
    ]
mp_hands = _FakeHands()
oldTime = time.time()
frame_width = 0
cam = 0
Percent = 0
TotalCycles = 0

cap = cv2.VideoCapture(cam)  # CAP_DSHOW retiré (Windows uniquement)
cap.set(cv2.CAP_PROP_FPS, 30)
#cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
time.sleep(1)  #

#desired_fps = 30  # Change this value to the desired frame rate
#cap.set(cv2.CAP_PROP_FPS, desired_fps)
cnt = 0
# while (frame_width==0):
#
#     cap = cv2.VideoCapture(cam)
#     frame_width = int(cap.get(3))
#     if cnt<20:
#         cnt+=1
#     else:
#
#         cam=0


# cap = cv2.VideoCapture(1)
#time.sleep(2)

Data1 = []
logging = True
Cycle = False
Cycle = False
Online_Stat = True
mockprediction=False
user_input = "y"
TOTALDATA = 0


UnityCommandRecivedstat= ["doNothing", "Record", "SendResults"]
frame_width = int(cap.get(3))  # Obtener el ancho del cuadro
frame_height = int(cap.get(4))  # Obtener la altura del cuadro

print("Frame resolution: ", frame_width, frame_height)
UserNameFromUnity="UnknownUser"
UnityStage=0
UnityParts=0
frame_width=600
frame_height=340

class FMNIST_Net2(nn.Module):
  """
  Neural Network instance
  """

  def __init__(self, num_classes):
    """
    Initialise parameters of FMNIST_Net2
    Args:
      num_classes: int
        Number of classes
    Returns:
      Nothing
    """
    super(FMNIST_Net2, self).__init__()

    self.conv1 = nn.Conv2d(3, 32, kernel_size=3, padding=1)
    self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
    self.dropout1 = nn.Dropout(0.5)
    self.dropout2 = nn.Dropout(0.25)
    self.fc1 = nn.Linear(2*320000, 128)
    self.fc2 = nn.Linear(128, num_classes)


    # self.conv1 = nn.Conv2d(3, 16, kernel_size=3, padding=1)
    # self.conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)
    # self.pool = nn.MaxPool2d(kernel_size=2, stride=2)
    # self.fc1 = nn.Linear(32 * 8 * 8, 128)
    # self.fc2 = nn.Linear(128, num_classes)

  def forward(self, x):
    """
    Forward pass of FMNIST_Net2
    Args:
      x: torch.tensor
        Input features
    Returns:
      x: torch.tensor
        Output after passing through FMNIST_Net2
    """
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

# criterion =  nn.CrossEntropyLoss()
DEVICE= torch.device('cpu')
model1 = FMNIST_Net2(num_classes=2).to(DEVICE)
optimizer = torch.optim.SGD(model1.parameters(), lr=0.01, momentum=0.9,weight_decay=0.003)
sent=False
import tensorflow as tf
fileP = '/Users/magloire/wheelsims/python:app/models/2024-08-06 15_09_56.698855model_best_checkpoint.pth'


MODEL= load_checkpoint(fileP)





device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# the socket is blocking the routne of Mediapipe, we use Threading in a class to command the logging of data by comunication with Unity
class LoggingHandler:
    def __init__(self):
        self.logging = True
        self.Val = 10
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.server_socket.settimeout(1)
        self.server_socket.bind(("127.0.0.1", 5052))  # Puedes cambiar la dirección y el puerto según tus necesidades
        self.connectioEstablished=False
        self.event = Event()
        self.receive_thread = Thread(target=self.logging_data)
        self.receive_thread.start()
        self.IsWaitingUnity = False
        self.is_supervised=UnityCommandRecivedstat[0]
        self.username=""
        self.stage=0
        self.parts=0

    # Socket comunication with python
    def logging_data(self):
        while True :
            connectioEstablished = self.event.is_set()



            try:
                data, addr = self.server_socket.recvfrom(1024)

                received_data = data.decode('utf-8')

                components = received_data.split(',')
                if len(components) >3:
                    self.is_supervised = components[0]
                    self.username= components[1]
                    self.stage= int(components[2])
                    self.parts=int(components[3])
                else:
                    self.is_supervised = UnityCommandRecivedstat[0]
                    self.username = ""
                    self.stage = 0
                    self.parts = 0
                    print(f"Waiting for the Connection")
            except socket.timeout:
                self.is_supervised = UnityCommandRecivedstat[0]
                self.username = ""
                self.stage = 0
                self.parts = 0
                print("No connection yet, retrying...")
                continue






            if self.is_supervised == UnityCommandRecivedstat[1]:
                self.logging = True
               # print('Data received is', self.is_supervised)
                self.IsWaitingUnity = False
                self.val = 1
            elif self.is_supervised == UnityCommandRecivedstat[2]:
                # print('Data received is', received_data)
                self.logging = False
                self.IsWaitingUnity = False
                self.val = 0
            elif self.is_supervised == UnityCommandRecivedstat[0]:
                # print('Data received is', received_data)
                self.logging = False
                self.IsWaitingUnity = True

                self.val = -1
            time.sleep(0.001)


class Offline_Mode():
    def __init__(self, NumberOfTotalFrame):
        self.logging = True
        self.Threshold = 300
        self.NOTF = NumberOfTotalFrame
        if self.NOTF <= self.Threshold:
            self.logging = True
            print('TOTAL Frame is', self.NOTF)


        else:
            # print('Data received is', received_data)
            self.logging = False

        time.sleep(0.001)


class SendingHandler:

    def __init__(self):
        self.logging = True
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.server_socket.settimeout(1)
        self.server_socket.bind(("127.0.0.1", 5054))  # You can change the address and port according to your needs

    def receive_data(self):
        try:
            data, addr = self.server_socket.recvfrom(1024)
            print("Received data:", data.decode())
        except socket.timeout:
            print("No data received within timeout period.")
            pass

    def send_data(self, message, address, port):
        self.server_socket.sendto(message.encode(), (address, port))
        # print("Sent data:", message)
        self.logging = False

    def close_socket(self):
        self.server_socket.close()


# Normalization of data to fit the dataframe sizes in a 50*50 matrix
def map_range(x, in_min, in_max, out_min, out_max):
    if x > in_max:
        print("WOOOOWWWW", x, in_max)

    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min


sending = SendingHandler()


Semi_cat=[]
NonSemicat=[]
def processData(MyData, samples):
    cccn = 0
    cross = 0
    Y = []
    X = []
    T = []

    print(MyData)
    Num_semi = 0
    TotalCycles = 0
    for i in range(0, len(MyData)):
        coordinatesx = []
        coordinatesy = []
        Tuplex = []
        Tupley = []

        # MyData is a tuple, to access to X adn Y data we must convertit in a numpy array
        # if i < 1:
        #     Data = np.array(MyData[0:samples[i]])
        # else:
        #     Data = np.array(MyData[samples[i-1]:samples[i]])

        Y.append(MyData[i][2])
        X.append(MyData[i][1])
        T.append(MyData[i][0])

        # print("Woow",T, X, Y)

        # here we plot the Y vector to visualize the executed patern by one of its coordinates
        # plt.plot(Y, label='Data Points')
        # plt.axhline(np.mean(Y), color='r', linestyle='--', label='mean value')
        # plt.show()
        #
        print('iteracion', i)
    proximity = 0;
    imagetest = np.zeros((400, 400), dtype=np.uint8)
    for j in range(1, len(X)):
        # add X and Y to a list

        # print("MEAN X", np.mean(X), X[j - 1])

        if cross > 0:
            coordinatesx.append(int(X[j]))
            coordinatesy.append(int(Y[j]))

        # mean value crossing of the vector Y, crossing 3 times indicates that a whole propusion cycle has been executed

        if (((X[j - 1] - np.mean(X)) * (X[j] - np.mean(X))) < 0 and j - proximity > 5):
            cross += 1
            print("cross ", cross)
            proximity = j

            if cross == 3:
                # here we create a matrix of 50*50
                matrix_coordinatesx = np.array(coordinatesx)
                matrix_coordinatesy = np.array(coordinatesy)
                coordinatesx = []
                coordinatesy = []

                Tuplex = []
                Tupley = []
                matrix_OrgSize = np.zeros((200,200,3), dtype=np.uint8)

                for iii in range(0, len(matrix_coordinatesx)):
                    center_coordinates = (int(matrix_coordinatesx[iii]/3), int(matrix_coordinatesy[iii]/3))
                    radius = 1
                    color = (255, 255, 255)
                    thickness = 2
                    cv2.circle(matrix_OrgSize, center_coordinates, radius, color, thickness)
                    # cv2.circle(imagetest, center_coordinates, radius, color, thickness)
                    # cv2.circle(image, center_coordinates, radius, color, thickness)

                    #matrix_resized = cv2.resize(matrix_OrgSize, (50, 50), interpolation=cv2.INTER_AREA)

                    #matrix_resized = cv2.resize(matrix_resized, (200, 200), interpolation=cv2.INTER_AREA)

                Fmatrix_resized= matrix_OrgSize #cv2.flip(matrix_resized, 1)

                # matrix = np.zeros((50, 50, 3), dtype=np.uint8)
                # center = (100, .75*image_height)
                ccx=int(image_width*(1/3)*.5)
                ccy=int(image_height*(1/3)*.85)
                center=(ccx,ccy)
                radius = int(Bigradius/(image_width)*200)


                #cv2.circle(Fmatrix_resized, center, int(radius), (0, 255, 0), 1)
                image_Org=  matrix_OrgSize.copy()


                cv2.circle(matrix_OrgSize, center, int(radius), (0, 0,255), 2)
                #Fmatrix_resized = cv2.flip(matrix_OrgSize, 1)



                # print("cycle did not detected completely")
                cross = 1


                matrix= matrix_OrgSize

                # update the values of the matrix with the normalized coordinates.
                # matrix[matrix_coordinatesy[:], matrix_coordinatesx[:]] = 255
                # matrix = cv2.flip(matrix, 1)
               # matrix = np.array(matrix,dtype=np.uint8)
                # matrix_OrgSize = cv2.flip(matrix_OrgSize, 1)
                # cv2.imshow('test', imagetest)
                nowfile = datetime.now()
                timestamp = nowfile.strftime("%Y%m%d_%H%M%S")

                if not os.path.exists(source_dir):
                    os.makedirs(source_dir)

                cv2.imshow('Matrix', matrix)
                filename = f"{"DetectedCycles/"}{str(TotalCycles)}{"_"}{timestamp}.{"jpg"}"
                cv2.imwrite(filename,matrix)
                TotalCycles += 1
                #cv2.imshow('Fmatrix', Fmatrix_resized)

                # cv2.imshow('Matrix org', matrix_OrgSize)

                #cv2.waitKey(5)
                # torch_tensor = torch.from_numpy(matrix)
                print("Cycle detected at :", j)
                cross = 1

                #matrix=cv2.imread('Semi_37.jpg')


                # plt.plot(matrix_coordinatesx)  #
                # MN = np.ones(len(matrix_coordinatesx)) * np.mean(X)
                # plt.plot(MN)
                # plt.title('image of patern', result)
                # plt.pause(0.5)  # Pause for a short time to show the plot
                # plt.draw()

                # matrix = cv2.imread('images/1.jpg',cv2.IMREAD_GRAYSCALE)

    #filename = f"{Classe}_{timestamp}.{"jpg"}"
    Semi_stat = []
    AllCycles = []
    for FileName in os.listdir(source_dir):

        if FileName.endswith('.jpg'):

            source_file = os.path.join(source_dir, FileName)
            print("FileName",source_file )
            im = cv2.imread(source_file)
            im = np.array(im)

            Classe= classify_images(im,MODEL,device)

            AllCycles.append(im)
            if Classe==0:
                SEMI=1
                clss="Semi"
                Semi_stat.append("Semi")






            else:
                SEMI = 0
                clss = "NonSemi"

                NonSemi_path = "NonSemi"
                Semi_stat.append("NonSemi")








            Num_semi = Num_semi + SEMI

            #Percent=Num_semi/TotalCycles*100

            Sending("Calculating...", TotalCycles)





                # print the matrix as image
                #


    if TotalCycles==0:
        Percent=0
    else:
        Percent = int(Num_semi / TotalCycles * 100)

    if not os.path.exists("Plots"):
        os.makedirs("Plots")

    username_dir = "Plots/"+ str(UserNameFromUnity)
    if not os.path.exists(username_dir):
        os.makedirs(username_dir)

    Plot(AllCycles,Semi_stat, "PPPatterns ", str(UserNameFromUnity), str(UnityStage), str(UnityParts))

    Sending(Percent, TotalCycles)
    print('Percent: ', Percent, "       TotalCycles: ", TotalCycles)

    Num_semi = 0
    TTC=TotalCycles
    Prc=Percent
    TotalCycles = 0
    Percent=0

    if os.path.exists(source_dir):
        shutil.rmtree(source_dir)
        print(f"Deleted directory: {source_dir}")
        os.makedirs(source_dir)
        print(f"Directory does not exist: {source_dir}")
    else:
        os.makedirs(source_dir)
        print(f"Directory does not exist: {source_dir}")
    # plt.plot(X)  #
    # MN = np.ones(len(X)) * np.mean(X)
    # plt.plot(MN)
    # plt.title('image of patern', result)
    # plt.show()

    return (Prc, TTC)
    #return Percent, TotalCycles

    # send_data_to_Unity(Percent)





def Sending(Percent, TotalCycles):
    # sending.receive_data()
    if (TotalCycles == 0):
        sending.send_data("Not Enough data", "127.0.0.1", 5053)
    else:
        sending.send_data(str(Percent), "127.0.0.1", 5053)
    #   print("Message sent")
    time.sleep(.01)




# Load your model or object with map_location set to 'cpu'
#classes = ["Semi", "Non_Semi"]


#
# CNN_Model = FMNIST_Net2(num_classes=4)
# #
# state_dict = torch.load(model_path, map_location=torch.device('cpu'))
#
# # Apply the state dictionary to the model
# model=CNN_Model.load_state_dict(state_dict)
#
# optimizer = torch.optim.SGD(model.parameters(), lr=0.001, momentum=0.9,weight_decay=0.003)

#model, optimizer, epoch, val_loss = load_checkpoint(checkpoint_path)
#print(model, optimizer, epoch, val_loss)


from torch.functional import Tensor

image_transform = transforms.Compose([transforms.ToTensor()])

classes = ["Semi","Non-Semi"]


#def evaluate(image):
    # image = torch.cat([image, image, image], dim=1)
    #
    # image = image.repeat(1, 3, 1, 1)
    #
    # to_pil_transform = transforms.ToPILImage()
    #
    # image_input = to_pil_transform(image)
    #
    # transform = transforms.Compose([transforms.ToTensor(), transforms.Normalize(mean=[0.5], std=[0.5])])  # Normaliza la imagen
    #
    # input_data = transform(image_input).unsqueeze(0)
    #
    # output = model(input_data)

   # semi, output, Prb = classify(model, image_transform, image, classes)

   # return semi, output, Prb


# heritage of the features of class "LoggingHandler()" to the object "logging_handler"
if Online_Stat == True:
    print("On line Mode")
    logging_handler = LoggingHandler()
else:
    print("Off line Mode")
    logging_handler = Offline_Mode(TOTALDATA)


# all the Mediapipe stuff
def Some_stupid_Changes(Varx, Vary):
    Varx = (Varx / 1 * 1)
    Vary = (Vary / 1 * 1)
    return Varx, Vary


# Nouvelle API MediaPipe 0.10+ : HandLandmarker en mode VIDEO pour suivi continu
_base_options = mp_python.BaseOptions(model_asset_path='hand_landmarker.task')
_hand_options = HandLandmarkerOptions(
    base_options=_base_options,
    running_mode=mp_vision.RunningMode.VIDEO,
    num_hands=1,
    min_hand_detection_confidence=0.1,
    min_hand_presence_confidence=0.1,
    min_tracking_confidence=0.1
)

class _HandsWrapper:
    """Émule l'ancienne API mp.solutions.hands pour le reste du code."""
    def __init__(self):
        self._detector = HandLandmarker.create_from_options(_hand_options)
        self._timestamp_ms = 0

    def process(self, image_rgb):
        import time as _time
        self._timestamp_ms = int(_time.time() * 1000)  # timestamp réel en ms
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)
        detection_result = self._detector.detect_for_video(mp_image, self._timestamp_ms)
        return _ResultWrapper(detection_result)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self._detector.close()

class _LandmarkWrapper:
    def __init__(self, x, y, z=0):
        self.x = x
        self.y = y
        self.z = z

class _HandWrapper:
    def __init__(self, landmarks):
        self.landmark = [_LandmarkWrapper(lm.x, lm.y, lm.z) for lm in landmarks]

class _ResultWrapper:
    def __init__(self, result):
        if result.hand_landmarks:
            self.multi_hand_landmarks = [_HandWrapper(lms) for lms in result.hand_landmarks]
        else:
            self.multi_hand_landmarks = None

with _HandsWrapper() as hands:  # hand model

    while cap.isOpened():

        if Online_Stat == False:
            logging_handler = Offline_Mode(TOTALDATA)

        ret, frame = cap.read()
        frame_width = 600
        #frame_height = 340

        # BGR 2 RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = imutils.resize(image, width=frame_width)


        # Set Flag
        image.flags.writeable = False

        # Detections
        results = hands.process(image)

        # Set flag to true
        image.flags.writeable = True
        image_height, image_width, _ = image.shape
        #print ("res", image_height, image_width)
        # RGB 2 BGR
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
        #print("Recording...")

        # Rendering results
        print("Is_super", logging_handler.is_supervised)

        if logging_handler.is_supervised == UnityCommandRecivedstat[0]:
            print("Do Nothing...")
            TOTALDATA += 1
            Percent = 0
            TotalCycles = 0

        elif results.multi_hand_landmarks and logging_handler.logging and logging_handler.is_supervised==UnityCommandRecivedstat[1]:


            if sent==False:
                TOTALDATA += 1
                Percent = 0
                TotalCycles = 0

                random_integer=random.randint(20, 90)
                sent=True



            for num, hand in enumerate(results.multi_hand_landmarks):

                # Here we get the coordinates of wrist

                currentTime = time.time() - oldTime
                print(currentTime)

                wrist_landmark = hand.landmark[0]  # wrist is the hand landmark 0
                cx, cy = int(wrist_landmark.x * image_width), int(wrist_landmark.y * image_height)
                center_coordinates1 = (cx, cy)
                # normalization of the imege to get a 50*50 resolution
                if (cx >= image_width): cx = image_width - 1
                if (cy >= image_height): cy = image_height - 1
                if (cx <= 0): cx = 1
                if (cy <= 0): cy = 1

                # normX= map_range(float(cx), 0, image_width, 0, 50)
                # normY= map_range(float(cy), 0, image_height, 0, 50)
                # print("Hand LandMark", normX, normY)
                # adding the coordinates to the array whe logging is enabled

                Data1 = [currentTime, cx, cy]
                WristCoordinates.append(Data1)
                # print('logging data')
                flag = True
                iscodeanalusisrun = False
                Percent = 0
                TotalCycles = 0


                radius = 3
                color = (255, 0, 0)
                thickness = 3
                cv2.circle(image, center_coordinates1, radius, color, thickness)




                # Display the image with the dashed ellipse


                #mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS)

        elif logging_handler.is_supervised==UnityCommandRecivedstat[2]:

            if (sent):
                Percent = random_integer
                TotalCycles = random_integer
                sent=False


            if (mockprediction==True ):



                print("Percent",Percent)
                Sending(Percent, TotalCycles)



            else:


                if len(WristCoordinates) > 50 and iscodeanalusisrun == False:
                    print("Classification....", len(WristCoordinates))
                    Num_loggings = len(WristCoordinates)
                    Percent, TotalCycles = processData(WristCoordinates, Num_loggings)


                    iscodeanalusisrun = True
                    print(Percent, TotalCycles)
                    Sending(Percent, TotalCycles)

                elif len(WristCoordinates) <= 50 and iscodeanalusisrun == False:
                    print("Not enough data", len(WristCoordinates))
                    Num_loggings = len(WristCoordinates)

                    Percent = "Not enough data"
                    TotalCycles = 0
                    iscodeanalusisrun = True
                    print(Percent, TotalCycles)

                    Sending(Percent, TotalCycles)

                #user_input = input("Reset Data Log? (y/n): ")
               # if (user_input == "y"):
                #    TOTALDATA = 0
                #elif (user_input == "n"):
                #    break

            WristCoordinates = []
            Num_loggings = []



        else:
                iscodeanalusisrun = False

        center=(int(image_width/2),int(.85*image_height))
        proportion=(image_height/image_width)
        BigWidth=image_width
        Bigradius=int(160)

        cv2.circle(image, center, int(Bigradius), (0, 0, 255), 4)

        # Define ellipse parameters
        center_elips = (256 + 70, 256 - 80)  # Center of the ellipse
        axes = (70, 45)  # Major and minor axes lengths
        angle = 20  # Angle of rotation (clockwise)
        startAngle = 0  # Starting angle of the elliptical arc
        endAngle = 360  # Ending angle of the elliptical arc
        color = (0, 255, 0)  # Color in BGR format (here, green)
        thickness = 2  # Thickness of the ellipse outline (pixels)

        # Number of dashes


        # Calculate the angle increment for each dash
       # cv2.ellipse(image, center_elips, axes, angle, startAngle, endAngle, color, thickness)
        cv2.imshow('hand tracking', image)
        window_name = "Second Display Window"
        cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
        cv2.moveWindow(window_name, second_monitor.x, second_monitor.y)
        width = 800
        height = 600
        position1 = (50, 50)  # (x, y)
        position2= (50, 50+30)
        position3= (50, 50+30+30)

        # Define font, scale, color, and thickness
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = .8
        color = (255, 0, 0)  # BGR (Blue, Green, Red)
        thickness = 2
        if logging_handler.username=='':
            message="Unity communication is not detected..."
        else:
            message ="Username: "+logging_handler.username
            UserNameFromUnity=logging_handler.username
            UnityStage=logging_handler.stage
            UnityParts=logging_handler.parts





        # Add text to the image
        cv2.putText(image, message, position1, font, font_scale, color, thickness)
        cv2.putText(image, "Stage: "+str(logging_handler.stage), position2, font, font_scale, color, thickness)
        cv2.putText(image, "Part: "+str(logging_handler.parts), position3, font, font_scale, color, thickness)

        cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)
        cv2.imshow(window_name, image)


        # here you use the keyboard to process the data and then it stops mediapipe
        if cv2.waitKey(10) & 0xFF == ord('q'):
            print("classifying on quitting...")
            Quitting = True
            # logging_handler.event.set()
            # logging_handler.receive_thread.join()
            # print('quitting',Num_loggings)

            # processData(WristCoordinates, Num_loggings)
            break

    if 'results' in dir():
        results.multi_hand_landmarks  # results from the last frame

sending.close_socket()
cap.release()
cv2.destroyAllWindows()

_ = mp_hands.HAND_CONNECTIONS  # constantes de connexions

print('end')