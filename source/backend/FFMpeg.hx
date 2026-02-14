#if desktop
package backend;

import lime.math.Rectangle;
import haxe.io.Bytes;
import lime.app.Application;
import lime.graphics.Image;
import flixel.FlxG;
import lime.ui.Window;
import sys.FileSystem;

class FFMpeg {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var image:Image;
    var bytes:Bytes;
    var window:Window = null;
    var frameBuffer:Rectangle;
    var target = "render_video";
    var fileName = '';
    var fileExts = '.mp4';

    public var process:Process;
    public static var instance:FFMpeg;

    var codecList:Map<String, String> = [
        'H.264' => 'libx264',
        'H.264 (QSV)' => 'h264_qsv',
        'H.264 (NVENC)' => 'h264_nvenc',
        'H.264 (AMF)' => 'h264_amf',
        'H.264 (VAAPI)' => 'h264_vaapi',
        'H.265' => 'libx265',
        'H.265 (QSV)' => 'hevc_qsv',
        'H.265 (NVENC)' => 'hevc_nvenc',
        'H.265 (AMF)' => 'hevc_amf',
        'H.265 (VAAPI)' => 'hevc_vaapi',
        'VP8' => 'libvpx',
        'VP8 (VAAPI)' => 'libvpx_vaapi',
        'VP9' => 'libvp9',
        'VP9 (VAAPI)' => 'libvp9_vaapi',
        'AV1' => 'libsvtav1',
        'AV1 (NVENC)\n(Needs RTX4000~ lmao)' => 'av1_nvenc'
    ];

    public function new() { }

    public function init() {
        if(FileSystem.exists(target)) {
            if(!FileSystem.isDirectory(target)) {
                FileSystem.deleteFile(target);
                FileSystem.createDirectory(target);
            }
        } else FileSystem.createDirectory(target);

        window = Application.current.window;

        x = window.width;
        y = window.height;
    }

    public function setup() {
        if (!FileSystem.exists('ffmpeg.exe')) {
            trace("\"FFmpeg.exe\" not found, turning on preview mode...");
            ClientPrefs.data.previewRender = true;

            FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);

            return;
        }

        fileName = target + '/' + Paths.formatToSongPath(PlayState.SONG.song);
        if (FileSystem.exists(fileName + fileExts)) {
            var millis = CoolUtil.fillNumber(Std.int(haxe.Timer.stamp() * 1000.0) % 1000, 3, '0'.fastCodeAt(0));
            fileName += "-" + DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S-") + millis;
        }

        var tmp:String = ClientPrefs.data.codec;
        var isGPU:Bool = tmp.contains('QSV') || tmp.contains('NVENC') || tmp.contains('AMF') || tmp.contains('VAAPI');

        var arguments:Array<String> = [
            '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', x + 'x' + y,
            '-r', Std.string(ClientPrefs.data.targetFPS), '-i', '-',
            '-c:v', codecList[ClientPrefs.data.codec]
        ];
        switch (ClientPrefs.data.encodeMode) {
            case "CRF/CQP":
                arguments.push(isGPU ? '-qp' : '-crf');
                arguments.push(Std.string(ClientPrefs.data.constantQuality));
            case 'VBR', 'CBR':
                arguments.push('-b');
                arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                if (ClientPrefs.data.encodeMode == 'CBR') {
                    arguments.push('-maxrate');
                    arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                    arguments.push('-minrate');
                    arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                }
        }
        arguments.push(fileName + fileExts);
        
        if (!ClientPrefs.data.previewRender) trace("running " + arguments);
        process = new Process('ffmpeg', arguments);

        frameBuffer = new Rectangle(0, 0, x, y);
        FlxG.autoPause = false;
    }

    function getScreen() {
        image = window.readPixels();

        x = image.width;
        y = image.height;

        if(x != frameBuffer.width || y != frameBuffer.height)
            frameBuffer.setTo(0, 0, x, y);
    }

    public function pipeFrame():Void
    {
        getScreen();
        bytes = image.getPixels(frameBuffer);
        process.stdin.write(bytes);
    }

    public function destroy():Void
    {        
        if (process != null){
            if (process.stdin != null)
                process.stdin.close();
            process.close();
            process.kill();
        }

        FlxG.autoPause = ClientPrefs.data.autoPause;
    }
}
#end