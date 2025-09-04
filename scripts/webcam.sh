sudo modprobe v4l2loopback devices=1 video_nr=2 card_label=RTSP_Camera exclusive_caps=1 ffmpeg -i {rtsp url} -vf scale=1280:720 v4l2 /dev/video2
