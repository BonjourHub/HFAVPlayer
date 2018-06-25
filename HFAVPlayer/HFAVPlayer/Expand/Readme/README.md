###  输入模块
1.注册协议／格式／编解码器
2.打开媒体文件源，设置超时回调
3.寻找各个流，并打开对应解码器
4.初始化解码后的数据结构体
5.读取流内容并且解码
6.处理解码后的裸数据
7.关闭所有资源


---
[参考]
http://music-video.cn


1. 注册所有容器格式和CODEC:av_register_all()

2. 打开文件:av_open_input_file()

3. 从文件中提取流信息:av_find_stream_info()

4. 穷举所有的流，查找其中种类为CODEC_TYPE_VIDEO

5. 查找对应的解码器:avcodec_find_decoder()

6. 打开编解码器:avcodec_open()

7. 为解码帧分配内存:avcodec_alloc_frame()

8. 不停地从码流中提取出帧数据:av_read_frame()

9. 判断帧的类型，对于视频帧调用:avcodec_decode_video()

10. 解码完后，释放解码器:avcodec_close()

11. 关闭输入文件:av_close_input_file()

https://blog.csdn.net/a2657222/article/details/7566814
https://blog.csdn.net/leixiaohua1020/article/details/38868499

