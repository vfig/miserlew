//LOCK EXPLOSION
schema exp_lock
archetype DEVICES
volume -1
expfrog2 expfrog
env_tag (Event Death) (DeviceType Padlock)

//OPEN JAW TRAP DOOR
schema doorjaws_op
archetype DOORS
volume -1
doorm2c
env_tag (Event StateChange) (DoorType JawTrap)  (OpenState Open) (OldOpenState Closed Opening Closing)

//OPENING JAW TRAP DOOR
schema doorjaws_op2
archetype DOORS
volume -1
doors1o
env_tag (Event StateChange) (DoorType JawTrap)  (OpenState Opening Closing) (OldOpenState Open Closed Opening Closing)

//CLOSED JAW TRAP DOOR
schema doorjaws_cl
archetype DOORS
volume -1
doors1c
env_tag (Event StateChange) (DoorType JawTrap)  (OpenState Closed) (OldOpenState Open Opening Closing)
