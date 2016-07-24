//
//  FlyPlayer.m
//  flyplayer
//
//  Created by feng on 16/7/19.
//  Copyright © 2016年 feng. All rights reserved.
//

#import "FlyPlayer.h"
#import "FlyPlayerHeader.h"

@interface FlyPlayer (){
    
    NSThread *read_tid;
    NSThread *video_tid;
    
    VideoState *_is;
    AVInputFormat *file_iformat;
    int64_t start_time;
    int video_disable;
    int wanted_stream[AVMEDIA_TYPE_NB];
    
    
}



@end

@implementation FlyPlayer



#pragma mark - player control
-(void)preparePlayWithUrlStr:(NSString *)urlStr{
    [self doinit];
    av_register_all();
    avformat_network_init();
    
    _is = [self stream_open:[urlStr UTF8String] iformat:file_iformat];
}

-(void)doinit{
    start_time = AV_NOPTS_VALUE;
    
}

-(void)play{
    
}

-(void)pause{
    
}

static int decode_interrupt_cb(void *ctx)
{
    VideoState *is = ctx;
    return is->abort_request;
}

-(void)video_thread{
    
}

-(void)video_stream_component_open:(int)stream_index{
    
    AVFormatContext *ic = _is->ic;
    AVCodecContext *avctx;
    AVCodec *codec;
    const char *forced_codec_name = NULL;
    avctx = ic->streams[stream_index]->codec;
    
    codec = avcodec_find_decoder(avctx->codec_id);
    avctx->codec_id = codec->id;

    packet_queue_start(&_is->videoq);
    video_tid = [[NSThread alloc] initWithTarget:self selector:@selector(video_thread) object:nil];
    [video_tid start];
}

-(void)read_thread{
    AVFormatContext *ic = NULL;
    int err, i, ret;
    int st_index[AVMEDIA_TYPE_NB];
    AVPacket pkt1, *pkt = &pkt1;
    int eof = 0;
    int64_t stream_start_time;
    
    pthread_mutex_t wait_mutex;
    pthread_mutex_init(&wait_mutex, NULL);
    
    _is->last_video_stream = _is->video_stream = -1;
    _is->last_audio_stream = _is->audio_stream = -1;
    
    ic = avformat_alloc_context();
    ic->interrupt_callback.callback = decode_interrupt_cb;
    ic->interrupt_callback.opaque = _is;

    err = avformat_open_input(&ic, _is->filename, _is->iformat,NULL);
    if (err < 0) {
        ret = -1;
        goto fail;
    }
    _is->ic = ic;
    
    err = avformat_find_stream_info(ic, NULL);
    if (err < 0) {
        av_log(NULL, AV_LOG_WARNING,
               "%s: could not find codec parameters\n", _is->filename);
        ret = -1;
        goto fail;
    }
    _is->max_frame_duration = (ic->iformat->flags & AVFMT_TS_DISCONT) ? 10.0 : 3600.0;
    if (start_time != AV_NOPTS_VALUE) {
        int64_t timestamp;
        timestamp = start_time;
        if (ic->start_time != AV_NOPTS_VALUE){
            timestamp += ic->start_time;
            
        }
    }

    for (i = 0; i < ic->nb_streams; i++){
        ic->streams[i]->discard = AVDISCARD_ALL;
    }
    if (!video_disable){
        printf("video_disable\n");
        st_index[AVMEDIA_TYPE_VIDEO] =
        av_find_best_stream(ic, AVMEDIA_TYPE_VIDEO,
                            wanted_stream[AVMEDIA_TYPE_VIDEO], -1, NULL, 0);
    }
    for (i = 0; i < _is->ic->nb_streams; i++) {
        if (_is->ic->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            _is->video_st = _is->ic->streams[i];
            _is->video_stream = i;
            break;
        }
    }
    for (i = 0; i < _is->ic->nb_streams; i++) {
        if (_is->ic->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            _is->audio_st = _is->ic->streams[i];
            _is->audio_stream = i;
            break;
        }
    }
    
    if (_is->video_stream>=0) {
        AVCodecContext *avctx = _is->video_st->codec;
        VideoPicture vp = {.width = avctx->width, .height = avctx->height, .sar = av_guess_sample_aspect_ratio(ic,_is->video_st, NULL)};
        [self video_stream_component_open:_is->video_stream];
    }

    
fail:
    printf("fail\n");

}



#pragma mark - stream open
-(VideoState *)stream_open:(const char *)filename iformat:(AVInputFormat *)iformat{
    VideoState *is;
    is = av_mallocz(sizeof(VideoState));
    strcpy(is->filename, filename);
    is->iformat = iformat;
    packet_queue_init(&is->videoq);
    packet_queue_init(&is->audioq);
    
    pthread_cond_init(&is->continue_read_thread, NULL);

    init_clock(&is->vidclk, &is->videoq.serial);
    init_clock(&is->audclk, &is->audioq.serial);
    
    read_tid = [[NSThread alloc] initWithTarget:self selector:@selector(read_thread) object:nil];
    [read_tid start];
    
    return is;
}


@end
