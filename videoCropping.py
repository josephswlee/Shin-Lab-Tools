def autoCrop():
    #Iterate though files in directory
    for filename in os.listdir(directory):
        if filename.endswith(".mpg") or filename.endswith(".mp4"):
            path = os.path.join(directory, filename)
            input = ffmpeg.input(path)

            #Crop and lens correct left and right of video
            left = input.crop(x=0, y=0, width=640, height=480).filter('lenscorrection', cx=0.5, cy=0.5, k1=0.55, k2=-0.75)
            right = input.crop(x=640, y=0, width=640, height=480).filter('lenscorrection', cx=0.5, cy=0.5, k1=0.55, k2=-0.75)

            #Test lens correction
            # left_pic = left.trim(start_frame = 10)
            # left_pic.output("left.png").run()
            # right_pic = left.trim(start_frame=10)
            # right_pic.output("right.png").run()

            #Use command line to crop and output left and right videos
            dimensions = ["223:218:112:35"]
            command = f'ffmpeg -i {input} -filter_complex "[0:v]crop={dimensions[0]}[m1]" -map [m1] trial.mp4'

def split():
    directory = "Raw video"
    counter = 1
    for filename in os.listdir(directory):
        if filename.endswith(".mpg") or filename.endswith(".mp4"):
            path = os.path.join(directory, filename)
            input = ffmpeg.input(path)

            print(path, counter)
            # Crop, lens correct, and save left and right of video
            left = input.crop(x=0, y=0, width=640, height=480).filter('lenscorrection', cx=0.5, cy=0.5, k1=0.4, k2=-0.6).output(f'left{counter}.mpg').run()
            # right = input.crop(x=640, y=0, width=640, height=480).filter('lenscorrection', cx=0.5, cy=0.5, k1=0.4, k2=-0.6).output(f'right{counter}.mpg').run()
            counter += 1

            # left_pic = left.trim(start_frame = 10)
            # left_pic.output("left.png").run()
            # right_pic = right.trim(start_frame=10)
            # right_pic.output("right.png").run()
            
#path needs to be directory of where new videos are
def leftCrop():
    path = "/Users/sampleUser/Documents/shinlab/left.mpg"

    leftDimensions = ["210:210:110:30", "215:215:320:30", "215:215:105:243", "225:215:317:247"]
    mice = ["928","971","522", "520"]

    command = f'ffmpeg -i {path} -filter_complex "[0:v]crop={leftDimensions[0]}[m1];[0:v]crop={leftDimensions[1]}[m2];[0:v]crop={leftDimensions[2]}[m3];[0:v]crop={leftDimensions[3]}[m4]" -map [m1] {mice[0]}.mpg -map [m2] {mice[1]}.mpg -map [m3] {mice[2]}.mpg -map [m4] {mice[3]}.mpg'
    # command = f'ffmpeg -i {path} -filter_complex "[0:v]crop={leftDimensions[0]}[m1];[0:v]crop={leftDimensions[1]}[m2]" -map [m1] {mice[0]}.mpg -map [m2] {mice[1]}.mpg'

    os.system(command)

def rightCrop():
    path = "/Users/sampleUser/Documents/shinlab/right.mpg"

    rgihtDimensions = ["210:210:110:30", "215:215:320:30", "215:215:105:243", "225:215:317:247"]
    mice = ["978","969","909", "970"]
    # command = f'ffmpeg -i {path} -filter_complex "[0:v]crop={rgihtDimensions[0]}[m1];[0:v]crop={rgihtDimensions[1]}[m2];[0:v]crop={rgihtDimensions[2]}[m3];[0:v]crop={rgihtDimensions[3]}[m4]" -map [m1] {mice[0]}.mpg -map [m2] {mice[1]}.mpg -map [m3] {mice[2]}.mpg -map [m4] {mice[3]}.mpg'
    command = f'ffmpeg -i {path} -filter_complex "[0:v]crop={rgihtDimensions[0]}[m1]" -map [m1] {mice[0]}.mpg'

    os.system(command)

def lensCorrect():
    left = ffmpeg.input("left.png")
    right = ffmpeg.input("right.png")

    left.filter('lenscorrection', cx=0.5, cy=0.5, k1=0.4, k2=-0.6).output("leftCorrected.png").run()
    right.filter('lenscorrection', cx=0.5, cy=0.5, k1=0.4, k2=-0.6).output("rightCorrected.png").run()


# split()
# lensCorrect()
rightCrop()