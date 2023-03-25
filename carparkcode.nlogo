extensions [csv]
turtles-own[
  lastx         ;stores the xcor of the patch that the turtles were on last
  lasty         ;stores the ycor of the patch that the turtles were on last
  parkx         ;stores the xcor of the patch that the turtles parked from
  parky         ;stores the ycor of the patch that the turtles parked from
  timeParked    ;stores the time the turtle spent parked
  intendedStay  ;stores the time the turtle intends to stay (generated from random-normal)
  time2park     ;store the time the turtle took to park
  time2leave    ;stores the time the turtle took to leave after parking
  age
  occupancy
  gender
  entDist       ;stores distane from entrance
  tickDist      ;stores distane from nearest ticket machine
  spacex        ;stores xcor of space
  spacey        ;stores ycor of space
  sides         ;stores how many cars parked adjacent
  direct        ;stores heading of car before parking
  mark          ;marks a point in time used to calculate time to park
  passed?       ;boolean that records true when agents pass a ticket machine
]

patches-own [
  remainingSpaceTik     ;stores percentage of 'desirable' spaces around a ticket machine
]

globals [
  poi
  poilist    ;a list of values generated via the random-poisson function
  parkTimes  ;a list of the times it took turtles to park
  leaveTimes ;a list of the times is took turtles to leave the car park
  failed
  ages
  noTurtles
  exportData
  agesCol
  genderList
  occupancyList
  siseList
  remainingSpace
  bOccupancy
  bDistance
  test
  ticketScarcity
  occupancyListX
  tickDistList
  entDistList
  sidesList
  genderListX
  sizeList
  agesW

]

to reset
  ;resets entire simulation

  ca
  importMap
  loadAttributes
  reset-ticks
  clear-all-plots
end

to start
  ;Checks conditions to ensure simualtion can run
  ;Dicates the order cars make decisions

  if count patches with [plabel = "Tickets"] = 0 and not FreeParking [
    user-message "ATTENTION: There must be one ticket machine when free parking is disabled"
    stop
  ]

  if randomSpawning [
    spawn
  ]

  if ticks >= 10000[
    stop
  ]
  tick

  if slowMode [
    wait 0.1
  ]
  set ticketScarcity []
  ask patches with [plabel = "Tickets"][
    set remainingSpaceTik (count patches in-radius 4 with [pcolor = yellow])
    set remainingSpaceTik (count patches in-radius 4 with [pcolor = yellow and not any? turtles-here])/ (count patches in-radius 6 with [pcolor = yellow])
    set ticketScarcity fput  remainingSpaceTik ticketScarcity
  ]

  ask turtles with [color = yellow][leave?]
  ask turtles with [color = blue][leave?]
  ask turtles with [color = blue] [drive]
  ask turtles with [color = yellow] [drive]
  ask turtles with [color = blue] [park?]
  ask turtles with [color = green] [stay]
  ask turtles with [color = red] [stay]
  set remainingSpace count patches with [pcolor = yellow and not any? turtles-here]

end

to spawn
  ;spawns turtles and assigns them values

  set poi random-poisson PoissonMean
  set poilist fput poi poilist
  set noTurtles (noTurtles + poi)

  create-turtles poi [
    if random-float 100 < 38 [set size 0.75]
    set shape "car top"
    set xcor 0
    set ycor -1
    set color blue
    set passed? false
    set gender one-of genderList
    set occupancy one-of occupancyList
    set label occupancy
    if gender = "male" [set label-color blue]
    if gender = "female"[set label-color pink]
    set lastx [pxcor] of patch-here
    set lasty [pycor] of patch-here
    set heading 90
    set intendedStay abs(floor(random-normal averagestay staySD))
    set time2park ticks
    set time2leave 0
    set mark ticks
    set age ticks
  ]

end

to drive
  ;logic that dictates how cars 'drive'

  carefully[
   ifelse ([pcolor] of patch-ahead 1 != grey)[lt 90]
    [
      ifelse ([pxcor] of patch-ahead 1 = lastx and [pycor] of patch-ahead 1 = lasty)[lt 90]
     [
      ifelse (not any? turtles-on patch-ahead 1)[
      set lastx ([pxcor] of patch-here)
      set lasty ([pycor] of patch-here)
      fd 1
        ]
      []
    ]
  ]
 ]

  [
    lt 90
  ]

end

to commencePark
    move-to patch spacex spacey
    set color green
    set heading 0
    set timeParked  0
    set time2park (ticks - mark)

end

to park?
  ;logic enabaling cars to park

  if any? neighbors4 with [plabel = "Tickets"][set passed? true]
  if (any? neighbors4 with [pcolor = yellow and not any? turtles-here]) and [plabel] of patch-here != "Gate" [

    set parkx ([pxcor] of patch-here)
    set parky ([pycor] of patch-here)
    set direct heading

    move-to one-of neighbors4 with [pcolor = yellow and not any? turtles-here]
    set spacex ([pxcor] of patch-here)
    set spacey ([pycor] of patch-here)
    move-to patch parkx parky

    investgateSpace

    if color = blue [

      if remainingSpace < 0.1 * count patches with [pcolor = yellow][commencePark]

      if gender = "male" and (sum [remainingSpaceTik] of patches < 0.2 or passed? = true) [
      if remainingSpace < 0.1 * count patches with [pcolor = yellow][commencePark]
      if gender = "male" and entDist < 10 [commencePark]
      if sides <= 1 [commencePark]
      if sides = 2 and (size = 0.75 or occupancy < 2) [commencePark]
    ]
      if gender = "male" and (tickDist <= 4 or entDist < 3) and freeParking = false[commencePark]
      if gender = "male" and [pycor] of patch-here  <= -6 and sum [remainingSpaceTik] of patches = 0 [commencePark]
      if gender = "female" [

        if remainingSpace < 0.1 * count patches with [pcolor = yellow][commencePark]
        if gender = "male" and entDist < 10 [commencePark]
        if sides <= 1 [commencePark]
        if sides = 2 and (size = 0.75 or occupancy < 2) [commencePark]
    ]
  ]
]

end

to investgateSpace
  ;subroutine for agents to collect information about a potential space

    set sides  0
    facexy spacex spacey
    fd 1
    lt 90

    carefully[if any? turtles-on patch-ahead 1[set sides (sides + 1)]][]
    rt 180
    carefully[ if any? turtles-on patch-ahead 1[set sides (sides + 1)]][]
    lt 90
  if not FreeParking[
    set tickDist distance (min-one-of (patches with [plabel = "Tickets"])[distance myself])
  ]
    set entDist distance (min-one-of (patches with [plabel = "Gate"])[distance myself])
    move-to patch parkx parky
    set heading direct
end

to stay
  ;logic check to see if cars have stayed thier intended time

  set timeParked timeParked + 1
  if timeParked > intendedStay[
    set color red
  ]
  if timeParked > intendedStay and not any? turtles-on patch parkx parky[
    move-to patch parkx parky
    set color yellow
    set time2leave ticks
  ]
end

to leave?
  ;logic for car leaving thier parking space
  ;logic for recording thier own data points
  ;removing turtles when they reach the exit

  if pxcor = 32 and pycor = -7[
    if color = blue [
      set failed (failed + 1)
      set agesCol fput "blue" agesCol
      set time2park 0
      set time2leave 0
    ]
    if color = yellow [
      set time2leave (ticks - time2leave)
      if time2leave > 1000 [set shape "car"]
      set agesCol fput "yellow" agesCol
    ]

    set age (ticks - age)
    set agesW fput who agesW
    set ages fput age ages
    set leaveTimes fput time2leave leaveTimes
    set parkTimes fput time2park parkTimes
    set tickDistList fput tickDist tickDistList
    set entDistList fput entDist entDistList
    set occupancyListX fput occupancy occupancyListX
    set genderListX fput gender genderListX
    set sidesList fput sides sidesList
    set sizeList fput size sizeList
    die
  ]

end

to merge
  ;labels every array of collected data, ammennd them to a larger array and writes to CSV

  set leaveTimes fput "LeaveTimes" leavetimes
  set parkTimes fput "parkTimes" parkTimes
  set ages fput "age" ages
  set agesW fput "ID" agesW
  set tickDistList fput "tickDist" tickDistList
  set entDistList fput "entDist" entDistList
  set occupancyListX fput "occupancy" occupancyListX
  set genderListX fput "gender" genderListX
  set sidesList fput "sides" sidesList
  set sizeList fput "size" sizeList

  let infoID (list "averagestay" "staySD" "poissionMean" "failed")
  let info (list averagestay staySD poissonMean failed)

  set exportData csv:from-file "exportdata.csv"

  set exportData lput infoID exportData
  set exportData lput info exportData
  set exportData lput leaveTimes exportData
  set exportData lput parkTimes exportData
  set exportData lput ages exportData
  set exportData lput agesW exportData
  set exportData lput entDistList exportData
  set exportData lput tickDistList exportData
  set exportData lput occupancyListX exportData
  set exportData lput genderListX exportData
  set exportData lput sidesList exportData
  set exportData lput sizeList exportData

  csv:to-file "exportdata.csv" (exportData)

end

to importMap
  ;sets the default map

  ask patches [set pcolor yellow
  set plabel ""]
  ask patches with [pycor = -1][set pcolor grey]
  ask patches with [pycor = -4][set pcolor grey]
  ask patches with [pycor = -7][set pcolor grey]
  ask patches with [((pxcor >= 31) and (pycor >= -3)) and ((pxcor <= 31 ) and (pycor <= -2 ))][set pcolor grey ]
  ask patches with [((pxcor >= 1) and (pycor >= -6)) and ((pxcor <= 1 ) and (pycor <= -5 ))][set pcolor grey ]
  ask patches with [((pxcor >= 32) and (pycor >= -4)) and ((pxcor <= 32 ) and (pycor <= 0 ))][set pcolor yellow ]
  ask patches with [((pxcor >= 0) and (pycor >= -8)) and ((pxcor <= 0 ) and (pycor <= -4 ))][set pcolor yellow ]
  ask patch 0 0 [set pcolor green]
  ask patch 0 -2 [set pcolor green]
  ask patch 0 -3 [set pcolor green]
  ask patch 0 -8 [set pcolor green]
  ask patch 32 0 [set pcolor green]
  ask patch 32 -5 [set pcolor green]
  ask patch 32 -8 [set pcolor green]
  ask patch 32 -6 [set pcolor green]
  ask patch 0 -1 [
    set pcolor red
    set plabel "Gate"
  ]
  ask patch 32 -7 [set plabel "Exit"]

end

to worldEdit
  ;logic required to be able to edit the parking environment

  if mouse-down? and ([pcolor] of patch mouse-xcor mouse-ycor != red and [plabel] of patch mouse-xcor mouse-ycor != "Exit")[
    if edit = "Ticket"[
    ask patch mouse-xcor mouse-ycor [
        set pcolor blue
        set plabel "Tickets"
      ]
      ask turtles-on patch mouse-xcor mouse-ycor [die]
    ]

    if edit = "Space"[
        ask patch mouse-xcor mouse-ycor [
        set pcolor yellow
        set plabel ""
      ]
      ask turtles-on patch mouse-xcor mouse-ycor [die]
      ]

    if edit = "Block"[
        ask patch mouse-xcor mouse-ycor [
        set pcolor green
        set plabel ""
      ]
      ask turtles-on patch mouse-xcor mouse-ycor [die]
      ]


    if edit = "Road"[
        ask patch mouse-xcor mouse-ycor [
        set pcolor grey
        set plabel ""
        ]
      ask turtles-on patch mouse-xcor mouse-ycor [die]
      ]

  ]


end

to loadAttributes
  ;resets all global lists and defines choices for certain categories
  clear-turtles
  set noTurtles 0
  set poilist []
  set parkTimes []
  set leaveTimes []
  set ages[]
  set ticketScarcity []
  set failed 0
  set agesW []
  set agesCol []
  set exportdata []
  set genderList (list "male" "female")
  set occupancyList (list 1 2 3 4)
  set siseList (List 0 1)
  set tickDistList []
  set entDistList []
  set sidesList []
  set genderListX []
  set occupancyListX []
  set sizeList []
end
@#$#@#$#@
GRAPHICS-WINDOW
24
297
1901
815
-1
-1
56.64
1
10
1
1
1
0
0
0
1
0
32
-8
0
0
0
1
ticks
30.0

BUTTON
5
125
171
169
Single Spawn
spawn\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
11
171
84
NIL
Start
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
87
172
120
Reset
reset\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
179
10
448
43
averagestay
averagestay
5
2000
2000.0
1
1
NIL
HORIZONTAL

SWITCH
179
110
307
143
randomSpawning
randomSpawning
0
1
-1000

PLOT
691
22
967
255
Turtles
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count turtles - count turtles-on patches with [pcolor = red])"

PLOT
1316
23
1623
255
Poisson Histogram
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 1 -16777216 true "" "histogram poilist"

SLIDER
179
76
448
109
PoissonMean
PoissonMean
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
179
43
448
76
staySD
staySD
0
500
500.0
1
1
NIL
HORIZONTAL

MONITOR
182
230
311
275
cars waiting to enter
count turtles-on patches with [pcolor = red]
17
1
11

MONITOR
317
230
441
275
Failed To Park
failed
17
1
11

MONITOR
565
10
670
55
NIL
mean parktimes
3
1
11

MONITOR
455
10
560
55
NIL
mean leavetimes
17
1
11

TEXTBOX
205
152
450
184
One IRL minute is 20 simulated ticks\n
13
0.0
0

SWITCH
309
110
449
143
slowMode
slowMode
1
1
-1000

PLOT
1641
25
1916
254
Leave Times
NIL
NIL
0.0
300.0
0.0
10.0
true
false
"set-plot-x-range 0 300\nset-histogram-num-bars 10" ""
PENS
"default" 20.0 1 -16777216 true "" "histogram leavetimes"

PLOT
980
17
1303
259
Park times
NIL
NIL
0.0
200.0
0.0
10.0
true
false
"set-plot-x-range 0 200\nset-histogram-num-bars 10" ""
PENS
"default" 20.0 1 -16777216 true "" "histogram parktimes"

MONITOR
455
60
560
105
NIL
noTurtles
17
1
11

BUTTON
5
170
171
214
Export Turtle Data
merge
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
565
60
670
105
Spaces Available
remainingSpace
17
1
11

CHOOSER
484
154
622
199
Edit
Edit
"Ticket" "Space" "Block" "Road"
0

BUTTON
484
117
622
150
Edit Layout
worldEdit\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
484
205
623
238
FreeParking
FreeParking
0
1
-1000

TEXTBOX
489
242
639
284
One ticket machine must be present when free parking is diabled
11
0.0
1

MONITOR
182
174
441
227
Time (Minutes)
ticks / 20
17
1
13

BUTTON
40
250
103
283
NIL
start
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# Traffic Simulation

## Interface
### Interface Elements

#### Time
By defualt the simualtion uses a minuet to tick ration of 1:20
This is by no mean the only conversion that can be used but a user must ensure all values are scaled appropriatly when changing the ratio.

#### Slow Mode
Slow mode is intended to be used to trouble shoot simualtions, it adds a 0.1 second delay to every tick so a user can see what agents are doing clearly.

#### Random Spawning
When deactivated there is no random spawning within the simulation. Turtles can be spawned manually using the 'single spawn' button.

#### Free Parking
When toggled on agents consider parking next to a ticket machine desireable a quality.

### Simulation
#### Turtle colour
Turtle colours indicate the phase of the stay for the agent. Blue indicates cars are searching to park, yellow indicates having parked, red indicates parked cars wating to leave
#### Patch Colours
Yellow patches indicate spaces and grey indicate the road. The red patch indactes the gate, blue the ticket machines. Green patches can be used to block out spaces.

#### Gate
The red gate patch is where agents queue to enter the car park. The amount of agents on this patch can be seen in a monitor in the interface.

## Internals

### Distribution Data
Agent spawn rate is controlled via a poission random variable, poission mean can be manipulated via the sliders in the GUI.

Agents intended duration to stay in the carpark. intended stays are ramdomised but based on a normal distribution of which its mean and SD can be controlled in the GUI.

### Parking Behaviour

The following properties dictate parking behaviour

* Distance from ticket machine
* Distance from enterance
* Occupancy & Size (how many adjacent bays are filled)
* Space Scarcity

The way these attributes contribute to the decison to park can be seen in the control staments in the park? function.

## Data Export
The export data function will export the following data values for every turtle to a file names data.CSV established in the same directory.

* LeaveTimes
* ParkTimes
* age
* ID
* entDist (distance from entrance)
* tickDist (distance from ticket machine)
* occupancy
* gender
* sides
* size

It also reports the Poisson mean and Normal mean and SD

This function breaks down is simualtions in behaviour space are ran in parallel. If running this function in final commands in behaviour space set simulationus paralell runs to 1

## World Edit
When the simualtion is paused, actiavting 'edit layout' will allow a user to chnage the layout of the carpark. Different patch type can be chose through the drop down menu.

Entrance  

World edit function can cause issue with turtle behaviour. Remember that turtles can only navigate a one-way system. Roads that have several options for turtles will produce errors or lead to redundancy in layouts.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

van top
true
0
Polygon -7500403 true true 90 117 71 134 228 133 210 117
Polygon -7500403 true true 150 8 118 10 96 17 85 30 84 264 89 282 105 293 149 294 192 293 209 282 215 265 214 31 201 17 179 10
Polygon -16777216 true false 94 129 105 120 195 120 204 128 180 150 120 150
Polygon -16777216 true false 90 270 105 255 105 150 90 135
Polygon -16777216 true false 101 279 120 286 180 286 198 281 195 270 105 270
Polygon -16777216 true false 210 270 195 255 195 150 210 135
Polygon -1 true false 201 16 201 26 179 20 179 10
Polygon -1 true false 99 16 99 26 121 20 121 10
Line -16777216 false 130 14 168 14
Line -16777216 false 130 18 168 18
Line -16777216 false 130 11 168 11
Line -16777216 false 185 29 194 112
Line -16777216 false 115 29 106 112
Line -7500403 false 210 180 195 180
Line -7500403 false 195 225 210 240
Line -7500403 false 105 225 90 240
Line -7500403 false 90 180 105 180

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Offical Data Sim" repetitions="10" runMetricsEveryStep="true">
    <setup>reset
ask patch 11 -6 [
set pcolor blue
set plabel "Tickets"
]</setup>
    <go>start</go>
    <final>file-close-all
merge
file-close-all</final>
    <timeLimit steps="10000"/>
    <steppedValueSet variable="averagestay" first="750" step="250" last="2000"/>
    <steppedValueSet variable="PoissonMean" first="0.02" step="0.02" last="0.1"/>
    <enumeratedValueSet variable="staySD">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSpawning">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowMode">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FreeParking">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimenttest" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>reset
ask patch 11 -6 [
set pcolor blue
set plabel "Tickets"
]</setup>
    <go>start</go>
    <final>merge
clear-all</final>
    <timeLimit steps="10000"/>
    <steppedValueSet variable="averagestay" first="1000" step="1000" last="2000"/>
    <enumeratedValueSet variable="PoissonMean">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="staySD">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSpawning">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowMode">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FreeParking">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ticket placement" repetitions="50" runMetricsEveryStep="true">
    <setup>reset
ask patch 11 -6 [
set pcolor blue
set plabel "Tickets"
]</setup>
    <go>start</go>
    <final>merge</final>
    <timeLimit steps="10000"/>
    <enumeratedValueSet variable="averagestay">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PoissonMean">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="staySD">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSpawning">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FreeParking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowMode">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
