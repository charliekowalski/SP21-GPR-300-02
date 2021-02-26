# animal3D-SDK-202101SP
animal3D SDK and related course frameworks for spring 2021.

Project 2 demonstrates the implementation of the **Bloom** post-processing effect using **Frame Buffer Objects**. This effect is achieved through the blending of Bright passes, Horizontal Blur passes, and Vertical Blur passes. The Bright > Blur H > Blur V is happening three times, and the resulting textures are blended with the original scene texture: Phong with Shadow Map.


**Controls and usage:** After running the Visual Studio project and having the Animal3D framework open, select File > DEBUG: Demo project hot build & load... > Quick build & load. When the program load successfully, you can use the WASDQE keys to move the camera around the world. Left clicking and dragging will rotate the camera with the mouse axes movement. Using the J and K keys will allow you to change between the rendering and shading modes: *Bright Pass* **Half**, *Blur Horizontal* **Half**, *Blur Vertical* **Half** **(repeat for quarter and eighth)**, *Blend* **(Bloom Effect)**, and *Shadow Map*.
