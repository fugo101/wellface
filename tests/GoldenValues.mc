// Recorded by GoldenTest from the default face before the settings-ready
// refactor (2026-11-14). Re-recorded for the themes derived from one accent
// (Q42, 2026-11-15): only the static layer's background and well rims
// changed. Re-recorded for the 86 px time and the wider time band
// (2026-11-15): only the time's width and position and the time band, its
// well and rim changed. Re-recorded for the new layout and the two-color
// date (2026-11-15): everything below the time band moved 6 px down, and
// the frame's date gained its two runs. Re-record only for an intended
// change to what is drawn; see GoldenTest.
import Toybox.Lang;

(:test)
module GoldenValues {
    const FRAMES = {
        "missing" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=SUN 01/01|" +
            "dateWidth=100|dateX=158|dateY=164|weekday=SUN|weekdayColor=8EE3B8|dayMonth=01/01|" +
            "dayMonthX=204|dayMonthColor=FFFFFF|datePill=R(144,162,128,28,14,000000)|" +
            "batteryLit=[]|bezelProgress=A(208,208,204,8,90,90,0,8EE3B8)|bezelHead=none|" +
            "goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|" +
            "iconY=344|iconColor=8C8C8C|number=--|numberFont=Number22|numberWidth=18|" +
            "numberX=210|numberY=341|numberColor=8C8C8C|goal=|goalX=233|goalY=0|" +
            "goalColor=000000}|left={arcs=[]|icon=U+E001|iconX=76|iconY=222|iconColor=8C8C8C|" +
            "number=--|numberColor=8C8C8C|numberFont=Number26|numberWidth=22|numberX=77|" +
            "numberY=247}|center={arcs=[]|icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|" +
            "number=--|numberColor=8C8C8C|numberFont=Number48|numberWidth=40|numberX=188|" +
            "numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|" +
            "number=--|numberColor=8C8C8C|numberFont=Number26|numberWidth=22|numberX=317|" +
            "numberY=247}",
        "typical" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "warning1" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,FF8A3D)A(208,208,180,4,117,112,5,FF8A3D)]|" +
            "bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|bezelHead=C(360,345,4,FFFFFF)|" +
            "goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|" +
            "iconY=344|iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|" +
            "numberX=175|numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|" +
            "goalColor=8C8C8C}|left={arcs=[A(88,252,35,6,90,234,216,FF8A3D)]|icon=U+E001|" +
            "iconX=76|iconY=222|iconColor=FF8A3D|number=60|numberColor=FF8A3D|" +
            "numberFont=Number26|numberWidth=34|numberX=71|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,18,72,FF8A3D)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=FF8A3D|number=20|numberColor=FF8A3D|numberFont=Number48|numberWidth=61|" +
            "numberX=178|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "warning2" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,FF4D4D)]|" +
            "bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|bezelHead=C(360,345,4,FFFFFF)|" +
            "goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|" +
            "iconY=344|iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|" +
            "numberX=175|numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|" +
            "goalColor=8C8C8C}|left={arcs=[A(88,252,35,6,90,162,288,FF4D4D)]|icon=U+E001|" +
            "iconX=76|iconY=222|iconColor=FF4D4D|number=80|numberColor=FF4D4D|" +
            "numberFont=Number26|numberWidth=34|numberX=71|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,54,36,FF4D4D)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=FF4D4D|number=10|numberColor=FF4D4D|numberFont=Number48|numberWidth=54|" +
            "numberX=181|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "zones1" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|" +
            "right={arcs=[A(328,252,35,6,86,22,64,B4B4B4)]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=100|numberColor=FFFFFF|numberFont=Number26|numberWidth=48|" +
            "numberX=304|numberY=247}",
        "zones2" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|" +
            "right={arcs=[A(328,252,35,6,86,22,64,B4B4B4)A(328,252,35,6,14,310,64,4DA6FF)]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=120|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=46|numberX=305|numberY=247}",
        "zones3" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|" +
            "right={arcs=[A(328,252,35,6,86,22,64,B4B4B4)A(328,252,35,6,14,310,64,4DA6FF)" +
            "A(328,252,35,6,302,238,64,4CD964)]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=140|numberColor=FFFFFF|numberFont=Number26|numberWidth=46|" +
            "numberX=305|numberY=247}",
        "zones4" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|" +
            "right={arcs=[A(328,252,35,6,86,22,64,B4B4B4)A(328,252,35,6,14,310,64,4DA6FF)" +
            "A(328,252,35,6,302,238,64,4CD964)A(328,252,35,6,230,166,64,FF8A3D)]|icon=U+E002|" +
            "iconX=316|iconY=222|iconColor=8C8C8C|number=160|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=46|numberX=305|numberY=247}",
        "zones5" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|" +
            "right={arcs=[A(328,252,35,6,86,22,64,B4B4B4)A(328,252,35,6,14,310,64,4DA6FF)" +
            "A(328,252,35,6,302,238,64,4CD964)A(328,252,35,6,230,166,64,FF8A3D)" +
            "A(328,252,35,6,158,94,64,FF4D4D)]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=180|numberColor=FFFFFF|numberFont=Number26|numberWidth=46|" +
            "numberX=305|numberY=247}",
        "zonesMissing" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=140|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=46|numberX=305|numberY=247}",
        "goalReached" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,90,360,8EE3B8)|" +
            "bezelHead=C(208,4,4,FFFFFF)|goalReached=yes|" +
            "bottom={pill=R(126,336,164,40,20,8EE3B8)|icon=U+E003|iconX=167|iconY=344|" +
            "iconColor=000000|number=3.110|numberFont=Number22|numberWidth=55|numberX=195|" +
            "numberY=341|numberColor=000000|goal=|goalX=0|goalY=0|goalColor=000000}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "goalReachedLong" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,90,360,8EE3B8)|" +
            "bezelHead=C(208,4,4,FFFFFF)|goalReached=yes|" +
            "bottom={pill=R(126,336,164,40,20,8EE3B8)|icon=U+E003|iconX=159|iconY=344|" +
            "iconColor=000000|number=12.345|numberFont=Number22|numberWidth=70|numberX=187|" +
            "numberY=341|numberColor=000000|goal=|goalX=0|goalY=0|goalColor=000000}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "steps100000" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,90,360,8EE3B8)|" +
            "bezelHead=C(208,4,4,FFFFFF)|goalReached=yes|" +
            "bottom={pill=R(126,336,164,40,20,8EE3B8)|icon=U+E003|iconX=148|iconY=344|" +
            "iconColor=000000|number=100.000|numberFont=Number22|numberWidth=92|numberX=176|" +
            "numberY=341|numberColor=000000|goal=|goalX=0|goalY=0|goalColor=000000}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "fiveDigits" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,126,324,8EE3B8)|" +
            "bezelHead=C(88,43,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=10.000|numberFont=Number18|numberWidth=62|numberX=166|" +
            "numberY=343|numberColor=FFFFFF|goal=/ 11.111|goalX=233|goalY=346|" +
            "goalColor=8C8C8C}|left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|" +
            "iconX=76|iconY=222|iconColor=8C8C8C|number=27|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=73|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=8C8C8C|number=56|numberColor=FFFFFF|numberFont=Number48|numberWidth=58|" +
            "numberX=179|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "negativeSteps" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,90,0,8EE3B8)|" +
            "bezelHead=none|goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|" +
            "icon=U+E003|iconX=140|iconY=344|iconColor=8C8C8C|number=--|numberFont=Number22|" +
            "numberWidth=18|numberX=210|numberY=341|numberColor=8C8C8C|goal=/ 3.110|goalX=233|" +
            "goalY=346|goalColor=8C8C8C}|left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|" +
            "icon=U+E001|iconX=76|iconY=222|iconColor=8C8C8C|number=27|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=73|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=8C8C8C|number=56|numberColor=FFFFFF|numberFont=Number48|numberWidth=58|" +
            "numberX=179|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "noGoal" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,90,0,8EE3B8)|" +
            "bezelHead=none|goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|" +
            "icon=U+E003|iconX=140|iconY=344|iconColor=8C8C8C|number=1.147|numberFont=Number22|" +
            "numberWidth=53|numberX=175|numberY=341|numberColor=FFFFFF|goal=|goalX=233|goalY=0|" +
            "goalColor=000000}|left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|" +
            "iconX=76|iconY=222|iconColor=8C8C8C|number=27|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=73|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=8C8C8C|number=56|numberColor=FFFFFF|numberFont=Number48|numberWidth=58|" +
            "numberX=179|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "dateLong" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=WEDNESDAY 28/11|" +
            "dateWidth=183|dateX=117|dateY=164|weekday=WEDNESDAY|weekdayColor=8EE3B8|" +
            "dayMonth=28/11|dayMonthX=247|dayMonthColor=FFFFFF|" +
            "datePill=R(103,162,211,28,14,000000)|batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)" +
            "A(208,208,180,4,117,112,5,8EE3B8)A(208,208,180,4,110,105,5,8EE3B8)" +
            "A(208,208,180,4,103,98,5,8EE3B8)A(208,208,180,4,96,91,5,8EE3B8)" +
            "A(208,208,180,4,89,84,5,8EE3B8)A(208,208,180,4,82,77,5,8EE3B8)]|" +
            "bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|bezelHead=C(360,345,4,FFFFFF)|" +
            "goalReached=no|bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|" +
            "iconY=344|iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|" +
            "numberX=175|numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|" +
            "goalColor=8C8C8C}|left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|" +
            "iconX=76|iconY=222|iconColor=8C8C8C|number=27|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=73|numberY=247}|" +
            "center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|icon=U+E000|iconX=196|iconY=219|" +
            "iconColor=8C8C8C|number=56|numberColor=FFFFFF|numberFont=Number48|numberWidth=58|" +
            "numberX=179|numberY=240}|right={arcs=[]|icon=U+E002|iconX=316|iconY=222|" +
            "iconColor=8C8C8C|number=72|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=313|numberY=247}",
        "dateTooLong" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=WED 28/11|" +
            "dateWidth=103|dateX=157|dateY=164|weekday=WED|weekdayColor=8EE3B8|dayMonth=28/11|" +
            "dayMonthX=207|dayMonthColor=FFFFFF|datePill=R(143,162,131,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "dateCyrillic" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=THU 12/11|" +
            "dateWidth=95|dateX=161|dateY=164|weekday=THU|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=206|dayMonthColor=FFFFFF|datePill=R(147,162,123,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "dateVietnamese" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=T5 12/11|" +
            "dateWidth=79|dateX=169|dateY=164|weekday=T5|weekdayColor=8EE3B8|dayMonth=12/11|" +
            "dayMonthX=198|dayMonthColor=FFFFFF|datePill=R(155,162,107,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "dateVietnameseSunday" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=CN 15/11|" +
            "dateWidth=84|dateX=166|dateY=164|weekday=CN|weekdayColor=8EE3B8|dayMonth=15/11|" +
            "dayMonthX=200|dayMonthColor=FFFFFF|datePill=R(152,162,112,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}",
        "dateDecember" =>
            "time=08:42|timeWidth=189|timeX=114|timeY=70|timeColor=000000|date=SAT 31/12|" +
            "dateWidth=96|dateX=160|dateY=164|weekday=SAT|weekdayColor=8EE3B8|dayMonth=31/12|" +
            "dayMonthX=204|dayMonthColor=FFFFFF|datePill=R(146,162,124,28,14,000000)|" +
            "batteryLit=[A(208,208,180,4,124,119,5,8EE3B8)A(208,208,180,4,117,112,5,8EE3B8)" +
            "A(208,208,180,4,110,105,5,8EE3B8)A(208,208,180,4,103,98,5,8EE3B8)" +
            "A(208,208,180,4,96,91,5,8EE3B8)A(208,208,180,4,89,84,5,8EE3B8)" +
            "A(208,208,180,4,82,77,5,8EE3B8)]|bezelProgress=A(208,208,204,8,90,318,132,8EE3B8)|" +
            "bezelHead=C(360,345,4,FFFFFF)|goalReached=no|" +
            "bottom={pill=R(126,336,164,40,20,000000)|icon=U+E003|iconX=140|iconY=344|" +
            "iconColor=8C8C8C|number=1.147|numberFont=Number22|numberWidth=53|numberX=175|" +
            "numberY=341|numberColor=FFFFFF|goal=/ 3.110|goalX=233|goalY=346|goalColor=8C8C8C}|" +
            "left={arcs=[A(88,252,35,6,90,353,97,8EE3B8)]|icon=U+E001|iconX=76|iconY=222|" +
            "iconColor=8C8C8C|number=27|numberColor=FFFFFF|numberFont=Number26|numberWidth=30|" +
            "numberX=73|numberY=247}|center={arcs=[A(208,262,56,9,90,249,201,8EE3B8)]|" +
            "icon=U+E000|iconX=196|iconY=219|iconColor=8C8C8C|number=56|numberColor=FFFFFF|" +
            "numberFont=Number48|numberWidth=58|numberX=179|numberY=240}|right={arcs=[]|" +
            "icon=U+E002|iconX=316|iconY=222|iconColor=8C8C8C|number=72|numberColor=FFFFFF|" +
            "numberFont=Number26|numberWidth=30|numberX=313|numberY=247}"
    } as Dictionary<String, String>;

    const AOD_FRAMES = {
        "typical" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=THU 12/11|dateX=159|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(145,162,123,28,14,6BAA8A)|" +
            "datePillInner=R(148,165,117,22,11,000000)|offsetX=-2|offsetY=0",
        "missing" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=SUN 01/01|dateX=156|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(142,162,128,28,14,6BAA8A)|" +
            "datePillInner=R(145,165,122,22,11,000000)|offsetX=-2|offsetY=0",
        "dateLong" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=WEDNESDAY 28/11|dateX=115|" +
            "dateY=164|dateColor=6BAA8A|datePill=R(101,162,211,28,14,6BAA8A)|" +
            "datePillInner=R(104,165,205,22,11,000000)|offsetX=-2|offsetY=0",
        "dateTooLong" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=WED 28/11|dateX=155|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(141,162,131,28,14,6BAA8A)|" +
            "datePillInner=R(144,165,125,22,11,000000)|offsetX=-2|offsetY=0",
        "dateCyrillic" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=THU 12/11|dateX=159|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(145,162,123,28,14,6BAA8A)|" +
            "datePillInner=R(148,165,117,22,11,000000)|offsetX=-2|offsetY=0",
        "dateVietnamese" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=T5 12/11|dateX=167|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(153,162,107,28,14,6BAA8A)|" +
            "datePillInner=R(156,165,101,22,11,000000)|offsetX=-2|offsetY=0",
        "dateVietnameseSunday" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=CN 15/11|dateX=164|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(150,162,112,28,14,6BAA8A)|" +
            "datePillInner=R(153,165,106,22,11,000000)|offsetX=-2|offsetY=0",
        "dateDecember" =>
            "time=08:42|timeX=112|timeY=70|timeColor=6BAA8A|date=SAT 31/12|dateX=158|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(144,162,124,28,14,6BAA8A)|" +
            "datePillInner=R(147,165,118,22,11,000000)|offsetX=-2|offsetY=0",
        "minute0" =>
            "time=23:54|timeX=112|timeY=70|timeColor=6BAA8A|date=THU 12/11|dateX=159|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(145,162,123,28,14,6BAA8A)|" +
            "datePillInner=R(148,165,117,22,11,000000)|offsetX=-2|offsetY=0",
        "minute1" =>
            "time=23:55|timeX=115|timeY=73|timeColor=6BAA8A|date=THU 12/11|dateX=162|dateY=167|" +
            "dateColor=6BAA8A|datePill=R(148,165,123,28,14,6BAA8A)|" +
            "datePillInner=R(151,168,117,22,11,000000)|offsetX=1|offsetY=3",
        "minute2" =>
            "time=23:56|timeX=118|timeY=70|timeColor=6BAA8A|date=THU 12/11|dateX=165|dateY=164|" +
            "dateColor=6BAA8A|datePill=R(151,162,123,28,14,6BAA8A)|" +
            "datePillInner=R(154,165,117,22,11,000000)|offsetX=4|offsetY=0",
        "minute3" =>
            "time=23:57|timeX=110|timeY=73|timeColor=6BAA8A|date=THU 12/11|dateX=157|dateY=167|" +
            "dateColor=6BAA8A|datePill=R(143,165,123,28,14,6BAA8A)|" +
            "datePillInner=R(146,168,117,22,11,000000)|offsetX=-4|offsetY=3",
        "minute4" =>
            "time=23:58|timeX=113|timeY=66|timeColor=6BAA8A|date=THU 12/11|dateX=160|dateY=160|" +
            "dateColor=6BAA8A|datePill=R(146,158,123,28,14,6BAA8A)|" +
            "datePillInner=R(149,161,117,22,11,000000)|offsetX=-1|offsetY=-4",
        "minute5" =>
            "time=23:59|timeX=117|timeY=72|timeColor=6BAA8A|date=THU 12/11|dateX=164|dateY=166|" +
            "dateColor=6BAA8A|datePill=R(150,164,123,28,14,6BAA8A)|" +
            "datePillInner=R(153,167,117,22,11,000000)|offsetX=3|offsetY=2",
        "minute6" =>
            "time=00:00|timeX=110|timeY=66|timeColor=6BAA8A|date=THU 12/11|dateX=157|dateY=160|" +
            "dateColor=6BAA8A|datePill=R(143,158,123,28,14,6BAA8A)|" +
            "datePillInner=R(146,161,117,22,11,000000)|offsetX=-4|offsetY=-4",
        "minute7" =>
            "time=00:01|timeX=115|timeY=69|timeColor=6BAA8A|date=THU 12/11|dateX=162|dateY=163|" +
            "dateColor=6BAA8A|datePill=R(148,161,123,28,14,6BAA8A)|" +
            "datePillInner=R(151,164,117,22,11,000000)|offsetX=1|offsetY=-1",
        "minute8" =>
            "time=00:02|timeX=118|timeY=74|timeColor=6BAA8A|date=THU 12/11|dateX=165|dateY=168|" +
            "dateColor=6BAA8A|datePill=R(151,166,123,28,14,6BAA8A)|" +
            "datePillInner=R(154,169,117,22,11,000000)|offsetX=4|offsetY=4",
        "minute9" =>
            "time=00:03|timeX=110|timeY=69|timeColor=6BAA8A|date=THU 12/11|dateX=157|dateY=163|" +
            "dateColor=6BAA8A|datePill=R(143,161,123,28,14,6BAA8A)|" +
            "datePillInner=R(146,164,117,22,11,000000)|offsetX=-4|offsetY=-1",
        "minute10" =>
            "time=00:04|timeX=113|timeY=72|timeColor=6BAA8A|date=THU 12/11|dateX=160|dateY=166|" +
            "dateColor=6BAA8A|datePill=R(146,164,123,28,14,6BAA8A)|" +
            "datePillInner=R(149,167,117,22,11,000000)|offsetX=-1|offsetY=2",
        "minute11" =>
            "time=00:05|timeX=118|timeY=67|timeColor=6BAA8A|date=THU 12/11|dateX=165|dateY=161|" +
            "dateColor=6BAA8A|datePill=R(151,159,123,28,14,6BAA8A)|" +
            "datePillInner=R(154,162,117,22,11,000000)|offsetX=4|offsetY=-3"
    } as Dictionary<String, String>;

    const STATIC_LAYER =
        "background=22362C|timeBandRim=R(56,70,304,104,32,446D58)|" +
        "fieldRims={C(208,262,68,446D58)C(328,252,46,446D58)C(88,252,46,446D58)}|" +
        "bottomFieldRim=R(124,334,168,44,22,446D58)|timeBandWell=R(58,72,300,100,30,000000)|" +
        "timeBand=R(64,78,288,88,24,8EE3B8)|bezelTrack=A(208,208,204,8,90,90,360,343B37)|" +
        "batteryWell=A(208,208,180,12,126,54,72,000000)|batteryCaps={C(102,62,6,000000)" +
        "C(314,62,6,000000)}|batteryTrack={A(208,208,180,4,103,98,5,2E3330)" +
        "A(208,208,180,4,110,105,5,2E3330)A(208,208,180,4,117,112,5,2E3330)" +
        "A(208,208,180,4,124,119,5,2E3330)A(208,208,180,4,61,56,5,2E3330)" +
        "A(208,208,180,4,68,63,5,2E3330)A(208,208,180,4,75,70,5,2E3330)" +
        "A(208,208,180,4,82,77,5,2E3330)A(208,208,180,4,89,84,5,2E3330)" +
        "A(208,208,180,4,96,91,5,2E3330)}|fieldWells={C(208,262,66,000000)C(328,252,44,000000)" +
        "C(88,252,44,000000)}|fieldTracks={A(208,262,56,9,90,90,360,2E3330)" +
        "A(328,252,35,6,14,310,64,2E3330)A(328,252,35,6,158,94,64,2E3330)" +
        "A(328,252,35,6,230,166,64,2E3330)A(328,252,35,6,302,238,64,2E3330)" +
        "A(328,252,35,6,86,22,64,2E3330)A(88,252,35,6,90,90,360,2E3330)}";
    const BEZEL_NOTCHES =
        "[L(406,208,418,208,3,000000)L(208,406,208,418,3,000000)L(10,208,-2,208,3,000000)" +
        "]";
    const LONG_PRESS_TARGETS =
        "--*21,ZP*10,--*21/--*17,ZP*18,--*17/--*15,ZP*5,--*12,ZP*5,--*15/" +
        "--*13,ZP*4,--*18,ZP*4,--*13/--*11,ZP*4,--*22,ZP*4,--*11/--*10,ZP*3,--*26,ZP*3,--*10/" +
        "--*9,ZP*3,--*28,ZP*3,--*9/--*8,ZP*2,--*32,ZP*2,--*8/--*7,ZP*2,--*34,ZP*2,--*7/" +
        "--*6,ZP*2,--*36,ZP*2,--*6/--*5,ZP*2,--*38,ZP*2,--*5/--*4,ZP*3,--*38,ZP*3,--*4/" +
        "--*4,ZP*2,--*40,ZP*2,--*4/--*3,ZP*2,--*42,ZP*2,--*3/--*3,ZP*2,--*42,ZP*2,--*3/" +
        "--*2,ZP*2,--*44,ZP*2,--*2/--*2,ZP*2,--*44,ZP*2,--*2/--*1,ZP*2,--*46,ZP*2,--*1/" +
        "--*1,ZP*2,--*46,ZP*2,--*1/--*1,ZP*2,--*46,ZP*2,--*1/--*1,ZP*1,--*48,ZP*1,--*1/" +
        "ZP*2,--*48,ZP*2/ZP*2,--*48,ZP*2/ZP*2,--*48,ZP*2/ZP*2,--*48,ZP*2/" +
        "ZP*2,--*20,CB*8,--*20,ZP*2/ZP*2,--*7,LS*4,--*8,CB*10,--*8,RH*4,--*7,ZP*2/" +
        "ZP*2,--*5,LS*8,--*5,CB*12,--*5,RH*8,--*5,ZP*2/" +
        "ZP*2,--*4,LS*10,--*3,CB*14,--*3,RH*10,--*4,ZP*2/" +
        "ZP*2,--*4,LS*10,--*2,CB*16,--*2,RH*10,--*4,ZP*2/" +
        "ZP*2,--*4,LS*10,--*2,CB*16,--*2,RH*10,--*4,ZP*2/" +
        "--*1,ZP*1,--*3,LS*12,--*1,CB*16,--*1,RH*12,--*3,ZP*1,--*1/" +
        "--*1,ZP*2,--*3,LS*10,--*2,CB*16,--*2,RH*10,--*3,ZP*2,--*1/" +
        "--*1,ZP*2,--*3,LS*10,--*2,CB*16,--*2,RH*10,--*3,ZP*2,--*1/" +
        "--*1,ZP*2,--*3,LS*10,--*2,CB*16,--*2,RH*10,--*3,ZP*2,--*1/" +
        "--*2,ZP*2,--*3,LS*8,--*3,CB*16,--*3,RH*8,--*3,ZP*2,--*2/" +
        "--*2,ZP*2,--*5,LS*4,--*6,CB*14,--*6,RH*4,--*5,ZP*2,--*2/" +
        "--*3,ZP*2,--*14,CB*14,--*14,ZP*2,--*3/--*3,ZP*2,--*15,CB*12,--*15,ZP*2,--*3/" +
        "--*4,ZP*2,--*15,CB*10,--*15,ZP*2,--*4/--*4,ZP*3,--*16,CB*6,--*16,ZP*3,--*4/" +
        "--*5,ZP*2,--*38,ZP*2,--*5/--*6,ZP*2,--*9,BP*18,--*9,ZP*2,--*6/" +
        "--*7,ZP*2,--*7,BP*20,--*7,ZP*2,--*7/--*8,ZP*2,--*6,BP*20,--*6,ZP*2,--*8/" +
        "--*9,ZP*3,--*4,BP*20,--*4,ZP*3,--*9/--*10,ZP*3,--*4,BP*18,--*4,ZP*3,--*10/" +
        "--*11,ZP*4,--*22,ZP*4,--*11/--*13,ZP*4,--*18,ZP*4,--*13/--*15,ZP*5,--*12,ZP*5,--*15/" +
        "--*17,ZP*18,--*17/--*21,ZP*10,--*21";
}
