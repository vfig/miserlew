//GHAST 1 -Dan Thron

/////////////
//AI SPEECH//
/////////////

//ASLEEP
schema gh1a0sn
archetype AI_NONE
volume -500
mono_loop 2000 3000
gh1a0sn1 gh1a0sn2 gh1a0sn3 
schema_voice vghast1 1 sleeping


//AT ALERT 0 - MUTTERING
// - ghasts are not happy and should mutter, not hum
schema gh1a0mu
archetype AI_NONE
volume -500
mono_loop 5000 20000
gh1a0mu1 gh1a0mu2 gh1a0mu3
schema_voice vghast1 1 atlevelzero
schema_voice vghast1 1 atlevelone

//		- TALKING TO HIMSELF
schema gh1a0co
archetype AI_NONE
volume -500
mono_loop 5000 20000
gh1m0201 gh1m0500 gh1m0501 gh1m0502 gh1m0503 gh1m0504
gh1m0505 gh1m0506 gh1m0507 gh1m0508 gh1m0509 gh1m0510
schema_voice vghast1 4 atlevelzero
schema_voice vghast1 4 atlevelone

//TO ALERT 1
schema gh1a1
archetype AI_NONE
gh1a1__1 gh1a1__2 gh1a1__3 gh1a1__4 gh1a1__5 gh1a1__6
schema_voice vghast1 1 tolevelone  

//		+sighted
schema gh1a1v
archetype AI_NONE
gh1a1v_1 gh1a1v_2
schema_voice vghast1 2 tolevelone (Sense Sight)

//		+heard
schema gh1a1h
archetype AI_NONE
gh1a1h_1 gh1a1h_2 gh1a1h_3
schema_voice vghast1 2 tolevelone (Sense Sound)

//		+w/co
schema gh1a1_w
archetype AI_MINOR
gh1a1_w1 gh1a1_w2
schema_voice vghast1 2 tolevelone (NearbyFriends 0 20)

//		+sighted +w/co
schema gh1a1vw
archetype AI_MINOR
gh1a1vw1 gh1a1vw2 gh1a1vw3 gh1a1vw4
schema_voice vghast1 3 tolevelone (Sense Sight) (NearbyFriends 0 20)

//		+heard +w/co
schema gh1a1hw
archetype AI_MINOR
gh1a1hw1 gh1a1hw2 gh1a1hw3 gh1a1hw4
schema_voice vghast1 3 tolevelone (Sense Sound) (NearbyFriends 0 20)


//AT ALERT 2 & 3
schema gh1a1tc
archetype AI_NONE
volume -500
delay 5000
mono_loop 2000 20000
gh1a0tc1 gh1a0tc2 gh1a0tc3 gh1a0cn1 gh1a0cn2 gh1a0cn3
schema_voice vghast1 1 atleveltwo
schema_voice vghast1 1 atlevelthree


//BACK TO ALERT 0
schema gh1bak
archetype AI_NONE
gh1bak_1 gh1bak_2 gh1bak_3 gh1bak_4 gh1bak_5 gh1bak_6 gh1bak_7 gh1bak_8 
schema_voice vghast1 1 backtozero  



//TO ALERT 2
schema gh1a2
archetype AI_MINOR
gh1a2__1 gh1a2__2 gh1a2__3 gh1a2__4 gh1a2__5
schema_voice vghast1 1 toleveltwo  

//		+sighted
schema gh1a2v
archetype AI_MINOR
gh1a2v_1
schema_voice vghast1 1 toleveltwo (Sense Sight)  

//		+heard
schema gh1a2h
archetype AI_MINOR
gh1a2h_1 gh1a2h_2 gh1a2h_3
schema_voice vghast1 2 toleveltwo (Sense Sound)


//AT ALERT 2 +Investigating
schema gh1at2
archetype AI_MINOR
delay 3000
no_repeat
mono_loop 10000 20000
gh1a2se1 gh1a2se2 gh1a2se3 gh1a2se4 gh1a3se1 gh1a3se2 gh1a3se3 gh1a3se4
schema_voice vghast1 99 atleveltwo (Investigate true)



//TO LEVEL THREE
schema gh1a3
archetype AI_MAJOR
gh1a3__1 gh1a3__2
schema_voice vghast1 1 tolevelthree


//SPOTTED THE PLAYER -All except THIEVE's MISSION
schema gh1a3s
archetype AI_MORE_MAJOR
gh1a3s_1 gh1a3s_2 gh1a3s_3 gh1a3s_4
schema_voice vghast1 1 spotplayer (Mission 1 14)
schema_voice vghast1 1 spotplayer (Mission 16 17)

//		-THIEVE's ONLY
schema gh1a3s_m15
archetype AI_MORE_MAJOR
gh1a3na7 gh1a3s_2 gh1a3s_4
schema_voice vghast1 1 spotplayer (Mission 15 15)

//(more sp)	-All except THIEVE's MISSION
schema gh1a3na
archetype AI_MORE_MAJOR
gh1a3na1 gh1a3na2 gh1a3na3 gh1a3na4 gh1a3na5 gh1a3na6 
schema_voice vghast1 1 spotplayer (Mission 1 14)
schema_voice vghast1 1 spotplayer (Mission 16 17)

//		-THIEVE's ONLY
schema gh1a3na_m15
archetype AI_MORE_MAJOR
gh1a3na1 gh1a3na2 gh1a3na3 gh1a3na4 gh1a3na7
schema_voice vghast1 1 spotplayer (Mission 15 15)

//		-OPERA ONLY
schema gh1a3na_m17
archetype AI_MORE_MAJOR
gh117100 gh117101 gh117102
schema_voice vghast1 1 spotplayer (Mission 17 17)


//		+carrying a body
schema gh1a3b
archetype AI_MORE_MAJOR
gh1a3b_1 
schema_voice vghast1 9 spotplayer (CarryBody True)

//		+w/co -All except THIEVE's
schema gh1telr
archetype AI_COMBAT
gh1telr1 gh1telr2 gh1telr3 gh1telr4 gh1telr5
schema_voice vghast1 3 spotplayer (NearbyFriends 0 20) (Mission 1 14)
schema_voice vghast1 3 spotplayer (NearbyFriends 0 20) (Mission 16 17)

//		+w/co -THIEVE's ONLY
schema gh1telr_m15
archetype AI_COMBAT
gh1telr4 gh1telr6 gh1telr7
schema_voice vghast1 3 spotplayer (NearbyFriends 0 20) (Mission 15 15)



//LOST CONTACT W/PLAYER
schema gh1los
archetype AI_NONE
gh1los_1 gh1los_2 gh1los_3 gh1los_4
schema_voice vghast1 1 lostcontact  



//AT ALERT 3 +Investigating
schema gh1at3
archetype AI_MAJOR
delay 3000
no_repeat
mono_loop 10000 20000
gh1a2se1 gh1a2se2 gh1a2se3 gh1a2se4 gh1a3se1 gh1a3se2 gh1a3se3 gh1a3se4
schema_voice vghast1 99 atlevelthree (Investigate true)



//RE-SPOTTED PLAYER AFTER A SEARCH +w/co -All except THIEVE's
schema gh1telc
archetype AI_COMBAT
gh1telc1 gh1telc2 gh1telc3 gh1telc4 gh1telc5 gh1telc6
schema_voice vghast1 3 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 1 14)
schema_voice vghast1 3 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 16 17)

//		-THIEVE's ONLY
schema gh1telc_m15
archetype AI_COMBAT
gh1telc3 gh1telc7
schema_voice vghast1 5 spotplayer (NearbyFriends 0 20) (Reacquire True) (Mission 15 15)


//REACT 1ST WARNING
schema gh1warn1
archetype AI_NONE
gh1wrn11
schema_voice vghast1 1 reactwarn

//REACT 2ND WARNING
schema gh1warn2
archetype AI_MINOR
gh1wrn21
schema_voice vghast1 1 reactwarn2

//REACT ATTACK AFTER FINAL WARNING
schema gh1warnf
archetype AI_MAJOR
gh1wrnf1
schema_voice vghast1 9 reactcharge (Reiterate 9 9)


//REACT CHARGE
schema gh1chga
archetype AI_MORE_MAJOR
gh1chga1 gh1chga2 
schema_voice vghast1 1 reactcharge

//		+w/co
schema gh1chgw
archetype AI_COMBAT
gh1chgw1 gh1chgw2 gh1chgw3
schema_voice vghast1 3 reactcharge (NearbyFriends 0 20)

//REACT CHARGE
schema gh1chga_M17
archetype AI_MORE_MAJOR
gh117100 gh117102 gh117103
schema_voice vghast1 1 reactcharge (Mission 17 17)

 

//REACT GET READY TO FIRE YOUR BOW
schema gh1bow
archetype AI_MORE_MAJOR
no_repeat
gh1atb_1 gh1atb_2 gh1atb_3 gh1atn_1
schema_voice vghast1 1 reactshoot



//REACT RUN AWAY -All except THIEVE's
schema gh1runa
archetype AI_MAJOR
gh1runa1 gh1runa2 gh1runa3 gh1runa4
schema_voice vghast1 1 reactrun (Mission 1 14)
schema_voice vghast1 1 reactrun (Mission 16 17)

//		-THIEVE's ONLY
schema gh1runa_m15
archetype AI_MAJOR
gh1runa1 gh1runa2 gh1runa3
schema_voice vghast1 1 reactrun (Mission 15 15)



//REACT I SOUND THE ALARMS
schema gh1alma
archetype AI_MORE_MAJOR
gh1alma1 gh1alma2 gh1alma3
schema_voice vghast1 1 reactalarm

//		+w/co
schema gh1almw
archetype AI_COMBAT
gh1almw1 gh1almw2
schema_voice vghast1 3 reactalarm (NearbyFriends 0 20)




//FRUSTRATION
schema gh1frust
archetype AI_MAJOR
gh1bkd_1 gh1bkd_2 gh1a2se2 gh1det_1
schema_voice vghast1 1 outofreach
 

//FOUND BODY
schema gh1bod
archetype AI_MORE_MAJOR
gh1bod_1 gh1bod_2 gh1bod_3
schema_voice vghast1 1 foundbody  



//FOUND SOMETHING MISSING -All except THIEVE's
schema gh1mis
archetype AI_MAJOR
gh1mis_1 gh1mis_2 gh1mis_5 gh1mis_6 gh1lar_2 
schema_voice vghast1 1 foundmissing (Mission 1 14)
schema_voice vghast1 1 foundmissing (Mission 16 17)

//		-BAFFORD ONLY
schema gh1mis_miss2
archetype AI_MAJOR
gh1mis_3
schema_voice vghast1 1 foundmissing (Mission 2 2)

//		-SWORD ONLY
schema gh1mis_m06
archetype AI_MAJOR
gh1mis_4 
schema_voice vghast1 1 foundmissing (Mission 6 6)

//		-THIEVE'S ONLY
schema gh1mis_m15
archetype AI_MAJOR
gh1mis_5 gh1mis_2 gh1mis_6 
schema_voice vghast1 5 foundmissing (Mission 15 15)



//NOTICED A TORCH BEING DOUSED
schema gh1torch
archetype AI_MINOR
delay 1000
gh1a1__1 gh1a1__2 gh1a1__3 gh1a1__6 gh1sma_4 gh1bak_6
schema_voice vghast1 1 noticetorch



//FOUND A SMALL ANOMALY
schema gh1sma
archetype AI_MINOR
gh1sma_1 gh1sma_2 gh1sma_3 gh1sma_4
schema_voice vghast1 1 foundsmall  

//FOUND A LARGE ANOMALY
schema gh1lar
archetype AI_MAJOR
gh1lar_1 gh1lar_3
schema_voice vghast1 1 foundlarge


//FOUND A SECURITY BREACH -All except THIEVE's
schema gh1sec
archetype AI_MORE_MAJOR
gh1sec_1 gh1sec_2 gh1sec_3 gh1sec_4
schema_voice vghast1 1 foundbreach (Mission 1 14)
schema_voice vghast1 1 foundbreach (Mission 16 17)

//		-THIEVE's ONLY
schema gh1sec_m15
archetype AI_MORE_MAJOR
gh1sec_1 gh1sec_2 gh1sec_3
schema_voice vghast1 1 foundbreach (Mission 15 15)



//RECENTLY SAW THE PLAYER +w/co All except THIEVE's
schema gh1rint
archetype AI_INFORM
gh1rint1 gh1rint2 gh1rint3
schema_voice vghast1 1 recentintruder (Mission 1 14) 
schema_voice vghast1 1 recentintruder (Mission 16 17) 

//		-THIEVE's ONLY
schema gh1rint_m15
archetype AI_INFORM
gh1rint4 gh1rint2 
schema_voice vghast1 1 recentintruder (Mission 15 15) 



//RECENTLY FOUND BODY +w/co -All except THIEVE's
schema gh1rbod
archetype AI_INFORM
gh1rbod1 gh1rbod2 gh1rbod4
schema_voice vghast1 1 recentbody (Mission 1 14) 
schema_voice vghast1 1 recentbody (Mission 16 17) 

//RECENTLY FOUND BODY +w/co -BAFFORD ONLY
schema gh1rbod_miss2
archetype AI_INFORM
gh1rbod3
schema_voice vghast1 2 recentbody (Mission 2 2)

//RECENTLY FOUND BODY +w/co -THIEVE's ONLY
schema gh1rbod_m15
archetype AI_INFORM
gh1rbod1 gh1rbod2
schema_voice vghast1 1 recentbody (Mission 15 15)



//RECENTLY FOUND SOMETHING MISSING +w/co -All except THIEVE's
schema gh1rmis
archetype AI_INFORM
gh1rmis1 gh1rmis2 gh1rmis7
schema_voice vghast1 1 recentmissing (Mission 1 14)
schema_voice vghast1 1 recentmissing (Mission 16 17)

//		-BAFFORD ONLY
schema gh1rmis_miss2
archetype AI_INFORM
gh1rmis1 gh1rmis3
schema_voice vghast1 5 recentmissing (Mission 2 2)

//		+w/co -SWORD ONLY
schema gh1rmis_m06
archetype AI_INFORM
gh1rmis4
schema_voice vghast1 3 recentmissing (Mission 6 6)

//		+w/co -THIEVE'S ONLY
schema gh1rmis_m15
archetype AI_INFORM
gh1rmis5 gh1rmis6 gh1rmis7
schema_voice vghast1 5 recentmissing (Mission 15 15)



//RECENTLY FOUND MISC ANAMOLY +w/co -All except THIEVE's
schema gh1roth
archetype AI_INFORM
gh1roth1 gh1roth2 gh1roth3 gh1roth4
schema_voice vghast1 1 recentother (Mission 1 14)
schema_voice vghast1 1 recentother (Mission 16 17)

//		-THIEVE's ONLY
schema gh1roth_m15
archetype AI_INFORM
gh1roth1 gh1roth2 gh1rint4
schema_voice vghast1 1 recentother (Mission 15 15)



//COMBAT
//ATTACKING +not losing
schema gh1atn
archetype AI_COMBAT
gh1atn_1 freq 1
gh1atn_2 freq 1
gh1atn_3 freq 3
gh1atn_4 freq 3
gh1atn_5 freq 3
schema_voice vghast1 1 comattack (ComBal Winning Even)

//		+winning
schema gh1atnw
archetype AI_COMBAT
gh1atw_1 gh1atw_2
schema_voice vghast1 2 comattack (ComBal Winning)

//		+winning +w/co
schema gh1atww
archetype AI_COMBAT
gh1atww1 
schema_voice vghast1 3 comattack (ComBal Winning) (NearbyFriends 0 20)

//		+losing
schema gh1atl
archetype AI_COMBAT
gh1atl_1 gh1atl_2 gh1atl_3 
schema_voice vghast1 2 comattack (ComBal Losing)



//SUCCESSFULLY HIT THE PLAYER +not losing
schema gh1hit
archetype AI_COMBAT
gh1hit_1 gh1hit_2 gh1hit_3 gh1hit_4
schema_voice vghast1 1 comsucchit (ComBal Winning Even)

//		+not losing +w/co
schema gh1hitw
archetype AI_COMBAT
gh1hitw1 gh1hitw2
schema_voice vghast1 2 comsucchit (ComBal Winning Even) (NearbyFriends 0 20)



//SUCCESSFULLY BLOCKED THE PLAYER +not losing
schema gh1blk
archetype AI_COMBAT
gh1blk_1 gh1blk_2 gh1blk_3
schema_voice vghast1 1 comsuccblock (ComBal Winning Even)

//		+not losing +w/co
schema gh1blkw
archetype AI_COMBAT
gh1blkw1
schema_voice vghast1 2 comsuccblock (ComBal Winning Even) (NearbyFriends 0 20)



//HIT BY THE PLAYER W/HI HIT PTS 
schema gh1hhi
archetype AI_MAJOR
gh1hhi_1 gh1hhi_2 gh1hhi_3
schema_voice vghast1 1 comhithigh

//HIT BY THE PLAYER W/LO PTS 
schema gh1hlo
archetype AI_MORE_MAJOR
gh1hlo_1 gh1hlo_2 gh1hlo_3 
schema_voice vghast1 1 comhitlow

//		+w/co
schema gh1hlow
archetype AI_COMBAT
gh1hlow1 gh1hlo_1 
schema_voice vghast1 2 comhitlow (NearbyFriends 0 20)

//HIT BY THE PLAYER NO DAMAGE
schema gh1hnd
archetype AI_MAJOR
gh1hnd_1 gh1hnd_2 gh1hnd_3 
schema_voice vghast1 1 comhitnodam



//BLOCKED BY THE PLAYER +not losing
schema gh1bkd 
archetype AI_COMBAT
gh1bkd_1 gh1bkd_2 gh1bkd_3
schema_voice vghast1 1 comblocked (ComBal Winning Even)

//		+not losing +w/co
schema gh1bkdw 
archetype AI_COMBAT
gh1bkdw1
schema_voice vghast1 1 comblocked (ComBal Winning Even) (NearbyFriends 0 20)
 


//DETECTED PLAYER TRYING TO BLOCK +not losing
schema gh1det 
archetype AI_COMBAT
gh1det_1 gh1det_2 gh1det_3
schema_voice vghast1 1 comdetblock(ComBal Winning Even)

//		+not losing +w/co
schema gh1detw 
archetype AI_COMBAT
gh1detw1
schema_voice vghast1 2 comdetblock (ComBal Winning Even) (NearbyFriends 0 20)


//AMBUSHED -HIT BY UNSEEN PLAYER
schema gh1amb 
archetype AI_MAJOR
gh1amb_1 gh1amb_2 gh1amb_3 gh1amb_4
schema_voice vghast1 1 comhitamb

//		+w/co
schema gh1ambw
archetype AI_COMBAT
gh1ambw1 gh1ambw2 gh1ambw3
schema_voice vghast1 2 comhitamb (NearbyFriends 0 20)


//DEATH BY COMBAT -LOUD
schema gh1diec
archetype AI_COMBAT
gh1diec1 gh1diec2 gh1diec3
schema_voice vghast1 1 comdieloud

//DEATH (or knocked out) BY AMBUSH -MORE MUFFLED
schema gh1diea
archetype AI_MINOR
volume -500
gh1diea1 gh1diea2 gh1diea3
schema_voice vghast1 1 comdiesoft
