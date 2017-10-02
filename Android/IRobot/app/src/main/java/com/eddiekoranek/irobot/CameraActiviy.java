package com.eddiekoranek.irobot;

import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ProgressBar;

import com.github.hiteshsondhi88.libffmpeg.ExecuteBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.FFmpeg;
import com.github.hiteshsondhi88.libffmpeg.LoadBinaryResponseHandler;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegCommandAlreadyRunningException;
import com.github.hiteshsondhi88.libffmpeg.exceptions.FFmpegNotSupportedException;
import com.otaliastudios.cameraview.CameraListener;
import com.otaliastudios.cameraview.CameraView;
import com.otaliastudios.cameraview.Facing;
import com.otaliastudios.cameraview.SessionType;
import com.otaliastudios.cameraview.VideoQuality;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;

import static com.eddiekoranek.irobot.R.drawable.ic_camera_overlay;
import static com.eddiekoranek.irobot.R.drawable.ic_record;
import static com.eddiekoranek.irobot.R.drawable.ic_send;
import static com.eddiekoranek.irobot.R.drawable.ic_stop;
import static java.security.AccessController.getContext;


public class CameraActiviy extends AppCompatActivity {

    private String terms = "I do hereby allow Michael McAvoy to use my face image as part of his sculpture \"iRobot: Prick us, do we not bleed\" He will use my face video behind the cast-resin face of the sculpture only. I do not give permission for my image to be shared or used in any other way. I understand that if this sculpture should sell, this agreement will transfer to the new owner.";

    private enum CameraState {
        RECORD,
        STOP,
        SEND
    }

    CameraState state;
    CountDownTimer timer;
    ProgressBar progressBar;
    ProgressBar ffmpegProgressBar;
    FloatingActionButton fab;
    CameraView cameraView;
    File file;
    File output;

    FFmpeg ffmpeg;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera_activiy);

        fab = findViewById(R.id.fab);
        progressBar = findViewById(R.id.progressBar);
        ffmpegProgressBar = findViewById(R.id.ffmpegProgress);
        ffmpegProgressBar.setVisibility(View.INVISIBLE);

        output = new File(this.getExternalFilesDir(null), "FinalVideo.mp4");

        setupCamera();
        setupFFmpeg();
        setupFAB();

        state = CameraState.RECORD;
    }

    @Override
    protected void onResume() {
        super.onResume();
        cameraView.start();
    }

    @Override
    protected void onPause() {
        super.onPause();
        cameraView.stop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        cameraView.destroy();
    }

    private void startRecording() {
        try {
            cameraView.startCapturingVideo(File.createTempFile("Recording", ".mp4", this.getExternalCacheDir()));
            startTimer();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void stopRecording() {
        cameraView.stopCapturingVideo();
        timer.cancel();
    }

    private void sendRecording() {
        progressBar.setProgress(0);
        showDialog();
    }

    private void startTimer() {
        timer = new CountDownTimer(10000, 100) {

            int i = 0;

            @Override
            public void onTick(long l) {
                i++;
                progressBar.setProgress(i*100/(10000/100));
            }

            @Override
            public void onFinish() {
                progressBar.setProgress(100);
                stopRecording();
                fab.setImageResource(ic_send);
                state = CameraState.SEND;
                return;
            }
        };
        timer.start();
    }

    public void composeEmail() {

        Uri path = Uri.fromFile(file);

        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:")); // only email apps should handle this
        intent.putExtra(Intent.EXTRA_EMAIL, new String[]{"irobot@studio407.net"});
        intent.putExtra(Intent.EXTRA_SUBJECT, "IRobot Submission");
        intent.putExtra(Intent.EXTRA_TEXT, terms);
        intent.putExtra(Intent.EXTRA_STREAM, path);
        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        }
    }

    public void showDialog() {
        final AlertDialog.Builder builder = new AlertDialog.Builder(this);

        builder.setTitle("Agreement");
        builder.setMessage(terms);
        builder.setPositiveButton("Agree", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                composeEmail();
            }
        });

        builder.setNegativeButton("Disagree", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {

            }
        });
        builder.show();
    }

    private void showFFMPEGDialog() {
        final AlertDialog.Builder builder = new AlertDialog.Builder(this);

        builder.setTitle("Unavailable");
        builder.setMessage("Sorry. Your device is not capable of rendering the final video.");

        builder.setNegativeButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {

            }
        });
        builder.show();
    }

    // This is the overlay code that I cannot get to work.
    private void addOverlay() {
        File overlay = getOverlayFile();

        String[] cmd = new String[]{  "-y", "-loop 1", "-i", file.getAbsolutePath(), "-i", overlay.getAbsolutePath(),"-filter_complex", "[1][0]scale2ref[i][m];[m][i]overlay[v]" ,"-map", "[v]", "-map",  "0:a?", "-ac", "2", output.getPath()};

        try {

            ffmpeg.execute(cmd, new ExecuteBinaryResponseHandler() {
                @Override
                public void onFailure(String s) {
                    System.out.println("on failure----"+s);
                }

                @Override
                public void onSuccess(String s) {
                    System.out.println("on success-----"+s);
                }

                @Override
                public void onProgress(String s) {
                    //Log.d(TAG, "Started command : ffmpeg "+command);
                    System.out.println("Started---"+s);


                }

                @Override
                public void onStart() {
                    //Log.d(TAG, "Started command : ffmpeg " + command);
                    System.out.println("Start----");}

                @Override
                public void onFinish() {
                    System.out.println("Finish-----");
                    // Send final file to email
                }
            });
        } catch (FFmpegCommandAlreadyRunningException e) {
            // do nothing for now
            System.out.println("exceptio :::" + e.getMessage());
        }
    }

    private File getOverlayFile() {
        try
        {
            File f= File.createTempFile("Overlay", ".jpg", this.getExternalCacheDir());
            InputStream inputStream = getResources().openRawResource(R.drawable.ic_camera_overlay);
            OutputStream out=new FileOutputStream(f);
            byte buf[]=new byte[1024];
            int len;
            while((len=inputStream.read(buf))>0)
                out.write(buf,0,len);
            out.close();
            inputStream.close();
            return f;
        }
        catch (IOException e) {
            return null;
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_camera_activiy, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void setupFFmpeg() {
        ffmpeg = FFmpeg.getInstance(this);

        try {
            ffmpeg.loadBinary(new LoadBinaryResponseHandler() {

                @Override
                public void onStart() {
                    ffmpegProgressBar.setVisibility(View.VISIBLE);
                    ffmpegProgressBar.setIndeterminate(true);
                }

                @Override
                public void onFailure() {
                    ffmpegProgressBar.setVisibility(View.INVISIBLE);
                }

                @Override
                public void onSuccess() {
                    ffmpegProgressBar.setVisibility(View.INVISIBLE);
                }

                @Override
                public void onFinish() {
                    ffmpegProgressBar.setVisibility(View.INVISIBLE);
                }
            });
        } catch (FFmpegNotSupportedException e) {
            e.printStackTrace();
            showFFMPEGDialog();
        }
    }

    private void setupFAB() {
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                switch (state) {
                    case RECORD:
                        startRecording();
                        fab.setImageResource(ic_stop);
                        state = CameraState.STOP;
                        return;

                    case STOP:
                        stopRecording();
                        fab.setImageResource(ic_send);
                        state = CameraState.SEND;
                        return;

                    case SEND:
                        sendRecording();
                        fab.setImageResource(ic_record);
                        state = CameraState.RECORD;
                        return;

                }
            }
        });
    }

    private void setupCamera() {
        cameraView = findViewById(R.id.camera);
        cameraView.setSessionType(SessionType.VIDEO);
        cameraView.setFacing(Facing.FRONT);
        cameraView.setVideoQuality(VideoQuality.MAX_720P);
        cameraView.addCameraListener(new CameraListener() {
            @Override
            public void onVideoTaken(File video) {
                super.onVideoTaken(video);
                file = video;
//                addOverlay();
            }
        });
    }
}
