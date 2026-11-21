package com.example.habittracker;

import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    private List<Habit> habitList;
    private HabitAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        habitList = new ArrayList<>();
        adapter = new HabitAdapter(habitList);

        RecyclerView recyclerView = findViewById(R.id.recyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        EditText etNewHabit = findViewById(R.id.etNewHabit);
        Button btnAddHabit = findViewById(R.id.btnAddHabit);

        btnAddHabit.setOnClickListener(v -> {
            String name = etNewHabit.getText().toString();
            if (!name.isEmpty()) {
                habitList.add(new Habit(name));
                adapter.notifyItemInserted(habitList.size() - 1);
                etNewHabit.setText("");
            }
        });
    }
}
