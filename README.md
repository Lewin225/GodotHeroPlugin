# GodotHeroPlugin 0.1
Godot .chart file loader


https://github.com/Lewin225/GodotHeroPlugin/assets/13208949/bd73317a-9dda-47bf-b866-57311cf6c73a


This godot addon can load .chart files and convert them into resources, you can even save them for later use

* Chart file must be in the standard folder layout, eg .chart file, with the music and images in the same folder
* Does not support .mid files
* Not all chart events are loaded yet, but notes, tempo and  lyrics are, which is enough the play the chart
* Todo : Doesn't read song.ini yet, so copy any missing fields into the notes.chart before loading


# Loading a chart

`var path = "songs\Lynyrd Skynyrd - Free Bird\notes.chart"`

`var chart:ChartSong = ChartReader.load_chart(path)`

"chart" will now contain the song metadata, great for making a song browser

`chart.full_load()`

"chart" will now also contain all the events in the chart, required to play it

![image](https://github.com/Lewin225/GodotHeroPlugin/assets/13208949/a0c972ab-831f-4925-9599-2d2c6dc47e9e)


# Accessing chart data

`print( chart.name )`
>Free Bird

`print( chart.get_sub_chart_list() )`
>["EasySingle", "EasyDoubleBass", "MediumSingle", "MediumDoubleBass", "HardSingle", "HardDoubleBass", "ExpertSingle", "ExpertDoubleBass"]

`print( chart.get_sub_chart('ExpertSingle').size() )`
> 3150

`print(chart.get_sub_chart('ExpertSingle')[2000])`
> Note Event position:127296  fret: 3 length:0

# Demo Scene

![B7aDMgYpQL](https://github.com/Lewin225/GodotHeroPlugin/assets/13208949/17e758a8-6205-40bc-bf1d-57629ea7f2f8)



Included is an example scene showing loading, playing, drawing and testing hits against a chart. 

Limitations! 
* Can't get good multi channel audio sync working, so will only try to play the "MusicStream" defined in the .chart file
* MusicStream must be mp3

You can also play the chart if you have a connected xinput controler / guitar. It does not implement guitar heros specific hit rules, you can either strum the notes or tap them, if they are taps. Held notes are not implemented

You can find it in `res://addons/GodotHero Chart Reader/Tipbits/CHART_LOADER_TEST_SCENE.tscn` 

Open the scene, and run it with F6, drag and drop a chart file into the window to load it, uncheck "Autoplay" if you want to use a controller

# Tools

A modified audiostream player (ChartSongPlayer) is included that provides a (get_playback_position() -> ticks conversion) implementation for playing back a chart, with a few utiility functions for testing a hit, fetching events at a tick, and dealing with tempo changes. plus a few signals you can connect to. Uses a very simple chache implementation for fetching any events at a given tick (Massive array), but it is constant time. Will allways read the first difficulty/subchart

If you are experieenced with the auto server manually mixing the audio by tick is probbaly a better way to go?


During loading ChartSong also computes a few utility properties for each event in the chart, eg. tempo changes now have the next temp change as a property, add more postprocessing in ChartSong.after_loaded()
  TODO : Add the behavour changes caused by frets 5, 6 and 7 eg. tap as bools to each note, so you don't have to check it while playing
