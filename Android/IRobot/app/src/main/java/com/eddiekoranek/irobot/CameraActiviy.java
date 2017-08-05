package com.eddiekoranek.irobot;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ProgressBar;

import static com.eddiekoranek.irobot.R.drawable.ic_record;
import static com.eddiekoranek.irobot.R.drawable.ic_send;
import static com.eddiekoranek.irobot.R.drawable.ic_stop;


public class CameraActiviy extends AppCompatActivity {

    private enum CameraState {
        RECORD,
        STOP,
        SEND
    }

    CameraState state;
    CountDownTimer timer;
    ProgressBar progressBar;
    FloatingActionButton fab;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera_activiy);

        fab = (FloatingActionButton) findViewById(R.id.fab);
        progressBar = (ProgressBar) findViewById(R.id.progressBar);

        state = CameraState.RECORD;

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

    private void startRecording() {
        startTimer();
    }

    private void stopRecording() {
        timer.cancel();
    }

    private void sendRecording() {
        progressBar.setProgress(0);
        composeEmail();
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
        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:")); // only email apps should handle this
        intent.putExtra(Intent.EXTRA_EMAIL, new String[]{"irobot@studio407.net"});
        intent.putExtra(Intent.EXTRA_SUBJECT, "IRobot Submission");
        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
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
}
