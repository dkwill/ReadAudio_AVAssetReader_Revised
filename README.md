# ReadAudio_AVAssetReader_Revised

Note: There is no UI output to the screen. All pertinent information is in Debug Window.

UI Image image2 is the expected frame of the hit. Place a breakpoint at those images and you can view the returns. 
Of the video files provided, only "output2.mp4" is correct. In all of the others, the actual hit frame is wrong as follows:

//RESULTS (Using arbitrary -2 frames on this line of code -> hitFrame = (int)hitFrameNumber-2; Also, using Sound Threshold of 6,500.
        
                         //Expected Hit Frame            //Actual Hit Frame        //Diff
        //output -               7                              5                    +2
        //output1 -              6                              3                    +3
        //output2 -              8                              8                     0
        //output3 -              7                              8                    -1
        //output4 -              8                              4                    +4
        
        //NOTE - Small part of the issue may be actual FPS is not always 240. All of the above were 240FPS actual except 
        "output1" which was 239.98
        
        Goal of the project is to correct whatever is causing the timing problem so that the correct "hit frame" is returned which will be then placed 
        into UI Image *image2. 
