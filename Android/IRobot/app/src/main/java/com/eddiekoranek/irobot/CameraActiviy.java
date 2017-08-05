package com.eddiekoranek.irobot;

import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;

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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera_activiy);

        final FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);

        state = CameraState.RECORD;

        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                switch (state) {
                    case RECORD:
                        fab.setImageResource(ic_stop);
                        state = CameraState.STOP;
                        return;

                    case STOP:
                        fab.setImageResource(ic_send);
                        state = CameraState.SEND;
                        return;

                    case SEND:
                        fab.setImageResource(ic_record);
                        state = CameraState.RECORD;
                        return;

                }
            }
        });
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
