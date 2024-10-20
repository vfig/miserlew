class FallLadder extends SqRootScript {
    function OnTurnOn() {
        local done = IsDataSet("Done");
        if (done)
            return;
        SetData("Done", 1);
        local rotvel = vector();
        rotvel.x = 1.0*Data.RandFltNeg1to1();
        rotvel.y = 1.0 + 2.0*Data.RandFlt0to1();
        rotvel.z = 2.0*Data.RandFltNeg1to1();
        if ("FallLadder_y" in userparams()) {
            local yFactor = userparams().FallLadder_y.tofloat();
            rotvel.y = rotvel.y*(yFactor);
        }
        SetProperty("PhysControl", "Controls Active", 0);
        Physics.Activate(self);
        SetProperty("PhysType", "Remove on Sleep", true);
        SetProperty("PhysState", "Rot Velocity", rotvel);
    }
}

class FlickerMomentary extends SqRootScript {
    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker
        && message().Op==eTweqOperation.kTweqOpFrameEvent) {
            SetProperty("RenderAlpha", 0.0);
            SetOneShotTimer("Unflicker", 0.2);
        }
    }

    function OnTimer() {
        if (message().name=="Unflicker") {
            SetProperty("RenderAlpha", 1.0);
        }
    }
}

class FrobLockSounds extends SqRootScript {
    function OnFrobWorldEnd() {
        Sound.PlayEnvSchema(self, "Event Reject, Operation OpenDoor",
            self, message().Frobber, eEnvSoundLoc.kEnvSoundAtObjLoc);
    }
}

class RevealDattachWhenUnlocked extends SqRootScript {
    function OnNowUnlocked() {
        // Reveal the dattached fake key.
        local links = Link.GetAll("~DetailAttachement", self);
        foreach (link in links) {
            local target = LinkDest(link);
            if (Property.Possessed(target, "RenderAlpha")) {
                Property.SetSimple(target, "RenderAlpha", 1.0);
            }
        }
    }
}

class SlayOwnedWhenUnlocked extends SqRootScript {
    function OnNowUnlocked() {
        // T1 doesn't Slay keys on use, so we have to. We keep track of our
        // key with an Owns link. Of course this only works because there is
        // just a single door for this key.
        local links = Link.GetAll("Owns", self);
        foreach (link in links) {
            local target = LinkDest(link);
            Damage.Slay(target, self);
        }
    }
}

class NotActuallyLoot extends SqRootScript {
    function OnBeginScript() {
        SwitchTextures("Stone");
    }

    function OnEndScript() {
        SwitchTextures("Gold");
        Object.RemoveMetaProperty(self, "M-NotActuallyLoot");
    }

    function OnContained() {
        local isPickup = (message().event==eContainsEvent.kContainAdd
            || message().event==eContainsEvent.kContainCombine);
        local isPlayer = Object.InheritsFrom(message().container, "Avatar");
        if (isPickup && isPlayer) {
            // Engine is hardcoded to change the name of an object with
            // "Loot" property to its loot stats when picked up. So we
            // change it back here, because it is junk right now!
            SetProperty("GameName", "");
        }
    }

    function SwitchTextures(keyPrefix) {
        local params = userparams();
        for (local i=0; i<4; i++) {
            local key = keyPrefix+i;
            local prop = "OTxtRepr"+i;
            if (key in params
            && HasProperty(prop)) {
                SetProperty(prop, params[key]);
            }
        }
    }
}

class TreasureSwitcher extends SqRootScript {
    // BUG: If you change from gold back to stone after the player picks some up
    //      (i.e. they have a loot stack in their inventory), then sometimes the
    //      junk will get combined into that loot pile. WONTFIX: For this mission,
    //      we ensure the player has no loot at all until after the stone->gold
    //      switch has happened; and we don't allow any gold->stone switch after
    //      the mission starts.

    function OnSim() {
        if (message().starting) {
            MakeLoot(false);
        }
    }

    function OnTurnOn() {
        MakeLoot(true);
    }

    function OnTurnOff() {
        // Disabled: we don't need it (and see bug note above).
        //MakeLoot(false);
    }

    function MakeLoot(becomeLoot) {

        if (becomeLoot) {
            Object.RemoveMetaPropertyFromMany("M-NotActuallyLoot", "@M-NotActuallyLoot");
        } else {
            Object.AddMetaPropertyToMany("M-NotActuallyLoot", "@SwitchTreasure,-@M-NotActuallyLoot");
        }
    }
}

/* ResLoot by FireMage, from The Black Parade. */
//Make Loot items get the ReplaceTextures properties for the newly stolen items
//so Loot using Replace Textures will keep their custom texture
//instead of displaying the ugly replace texture
class ResLoot extends SqRootScript
{
    function OnCombine()
    {
        //print("COMBINE : " +(message().combiner).tostring() + " " + self.tostring());
        local o = message().combiner;
        if(Property.Possessed(o,"OTxtRepr0"))
            SetProperty("OTxtRepr0",Property.Get(o,"OTxtRepr0"));
        if(Property.Possessed(o,"OTxtRepr1"))
            SetProperty("OTxtRepr1",Property.Get(o,"OTxtRepr1"));
        if(Property.Possessed(o,"OTxtRepr2"))
            SetProperty("OTxtRepr2",Property.Get(o,"OTxtRepr2"));
        if(Property.Possessed(o,"OTxtRepr3"))
            SetProperty("OTxtRepr3",Property.Get(o,"OTxtRepr3"));
    }
}

/* Sequence a pattern of TurnOn/TurnOff messages to a set of objects.
 *
 *    1. Add a ScriptParams link to each object to control, and set
 *       its data to a single letter A-Z.
 *
 *    2. Add a Design Note parameter, "Sequence", with the pattern
 *       made of comma-separated commands:
 *
 *           a      TurnOn object "a".
 *           !a     TurnOff object "a".
 *           123    pause for 123 milliseconds.
 *           stop   stop the sequence and turn off.
 *
 *    Turning the sequencer on will start the pattern from the beginning.
 *    Turning it off will stop the pattern, and turn off all the objects.
 */
enum SequenceAction {
    Stop,
    Wait,
    TurnOn,
    TurnOff,
}        
class Sequencer extends SqRootScript {
    parsed_sequence = [];

    function OnBeginScript() {
        EnableMe(false);
    }

    function OnTurnOn() {
        EnableMe(true);
    }

    function OnTurnOff() {
        EnableMe(false);
    }

    function OnTimer() {
        if (message().name=="SequencerWait") {
            DoNextStep();
        }
    }

    function EnableMe(enable) {
        if (enable) {
            local wasEnabled = (GetData("Enable")==1);
            if (! wasEnabled) {
                SetData("Enable", 1);
                SetData("Step", -1);
                SetData("Timer", 0);
                DoNextStep();
            }
        } else {
            local timer = GetData("Timer");
            if (timer!=null && timer!=0) {
                KillTimer(timer);
            }
            Link.BroadcastOnAllLinks(self, "TurnOff", "ScriptParams");
            SetData("Enable", 0);
            SetData("Step", -1);
            SetData("Timer", 0);
        }
    }

    function GetNextAction() {
        local seq = ParseSequence();
        if (seq.len()==0)
            return SequenceAction.Stop;
        local step = GetData("Step").tointeger()+1;
        if (step>=seq.len())
            step = 0;
        SetData("Step", step);
        return seq[step];
    }

    function DoNextStep() {
        while (true) {
            local action = GetNextAction();
            switch(action) {
            // Actions that are one-shot:
            case SequenceAction.Stop:
                EnableMe(false);
                return;
            case SequenceAction.Wait:
                local param = GetNextAction().tointeger();
                local s = param/1000.0;
                local t = SetOneShotTimer("SequencerWait", s);
                SetData("Timer", t);
                return;
            // Actions that keep looping:
            case SequenceAction.TurnOn:
                local who = GetNextAction().tostring();
                Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", who);
                break;
            case SequenceAction.TurnOff:
                local who = GetNextAction().tostring();
                Link.BroadcastOnAllLinksData(self, "TurnOff", "ScriptParams", who);
                break;
            }
        }
    }

    function ParseSequence() {
        if (parsed_sequence.len()>0)
            return parsed_sequence;
        if (! ("Sequence" in userparams())) {
            parsed_sequence = [SequenceAction.Stop];
            return parsed_sequence;
        }
        local names = {};
        local links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local data = LinkTools.LinkGetData(link, "");
            names[data] <- true;
        }
        local pattern = userparams().Sequence;
        pattern = pattern.tostring()+",";
        local seq = [];
        local start = 0;
        while(start<pattern.len()) {
            local end = pattern.find(",", start);
            if (end==null)
                end = pattern.len();
            local bit = pattern.slice(start, end);
            start = end+1;
            local delay;
            try {
                delay = bit.tointeger();
            } catch(e) {
                delay = 0;
            }
            if (delay>0) {
                seq.push(SequenceAction.Wait);
                seq.push(delay);
            } else if (bit=="stop") {
                seq.push(SequenceAction.Stop);
                break;
            } else {
                local off = (bit.slice(0,1)=="!");
                if (off)
                    bit = bit.slice(1);
                if (! (bit in names)) {
                    print("WARNING: Sequencer "+self+" has no ScriptParams link matching '"+bit+"'");
                }
                seq.push(off? SequenceAction.TurnOff:SequenceAction.TurnOn);
                seq.push(bit);
            }
        }
        if (seq.len()>0) {
            parsed_sequence = seq;
        } else {
            parsed_sequence = [SequenceAction.Stop];
        }
        return parsed_sequence;
    }
}

class ForceField extends SqRootScript {
    function OnTurnOn() {
        Activate(true);
    }

    function OnTurnOff() {
        Activate(false);
    }

    function Activate(enable) {
        SetProperty("CollisionType", (enable? 1:0));    // Bounce / None
        SetProperty("RenderType", (enable? 0:1));       // Normal / Not Rendered
    }
}

/* LUGGED
   For any especially heavy-seeming object (e.g. corpses, boulders).
   When the player picks such a thing up, there's a sound effect and
   he is slowed.
   (copied from T2)
   */
class Lugged extends SqRootScript {
    function OnContained() {
        if (Object.InheritsFrom(message().container, "Avatar")) {
            if (message().event==eContainsEvent.kContainAdd) {
                Sound.PlaySchemaAmbient(self, "garlift");
                DrkInv.AddSpeedControl("LuggedHeavy", 0.6, 0.9);
            } else if (message().event==eContainsEvent.kContainRemove) {
                Sound.PlaySchemaAmbient(self, "gardrop");
                DrkInv.RemoveSpeedControl("LuggedHeavy");
            }
        }
    }
}

class StartsOff extends SqRootScript
{
    // Put this on a n object to send it TurnOff when the mission starts.

    function OnSim()
    {
        if (message().starting) {
            SendMessage(self, "TurnOff");
        }
    }
}

class PedestalPuzzle extends SqRootScript {
    function OnTurnOn() {
        local sender = message().from;
        if (! Link.AnyExist("ScriptParams", self, sender)) {
            Link.Create("ScriptParams", self, sender);
        }
        Update();
    }

    function OnTurnOff() {
        local sender = message().from;
        local link = Link.GetOne("ScriptParams", self, sender);
        if (link!=0) {
            Link.Destroy(link);
        }
        Update();
    }

    function GetInputState() {
        local inputs = {};
        local links = Link.GetAll("~ControlDevice", self);
        foreach (link in links) {
            local name = Object.GetName(LinkDest(link));
            if (name!=null) {
                inputs[name] <- false;
            }
        }
        links = Link.GetAll("ScriptParams", self);
        foreach (link in links) {
            local o = LinkDest(link);
            local name = Object.GetName(o);
            if (name!=null
            && name in inputs) {
                inputs[name] = true;
            }
        }
        return inputs;
    }

    function ApplyResults(results) {
        local targets = {};
        local links = Link.GetAll("ControlDevice", self);
        foreach (link in links) {
            local o = LinkDest(link);
            local name = Object.GetName(o);
            if (name!=null) {
                targets[name] <- o;
            }
        }
        foreach (name,isOn in results) {
            if (! (name in targets)) continue;
            local o = targets[name];
            local link = Link.GetOne("ScriptParams", self, o);
            local wasOn = (link!=0);
            if (isOn && !wasOn) {
                Link.Create("ScriptParams", self, o);
                SendMessage(o, "TurnOn");
            } else if (!isOn && wasOn) {
                Link.Destroy(link);
                SendMessage(o, "TurnOff");
            }
        }
    }

    function Update() {
        local inputs = GetInputState();
        local results = Calculate(inputs);
        ApplyResults(results);
    }

    function Calculate(input) {
        local A = input["PedestalA"];
        local B = input["PedestalB"];
        local C = input["PedestalC"];
        local D = input["PedestalD"];
        local field1_open = (A || B) && !(A && B) || (C && D);
        local field2_open = (C && D);
        return {
            "ForceField1": !field1_open,
            "ForceField2": !field2_open,
        };
    }
}

class FaceNorth extends SqRootScript {
    function OnBeginScript() {
        PostMessage(self, "RestoreFacing");
    }

    function OnContained() {
        if (message().event==eContainsEvent.kContainRemove) {
            // Need to wait a frame for the teleport to work.
            PostMessage(self, "RestoreFacing");
        }
    }

    function OnRestoreFacing() {
        local f = vector(0.0,0.0,270.0);
        Object.Teleport(self, Object.Position(self), f);
    }
}

class FaceOutward extends SqRootScript {
    function OnBeginScript() {
        PostMessage(self, "RestoreFacing");
    }

    function OnContained() {
        if (message().event==eContainsEvent.kContainRemove) {
            // Need to wait a frame for the teleport to work.
            PostMessage(self, "RestoreFacing");
        }
    }

    function OnRestoreFacing() {
        local mid = 0.5*(Object.Position("PedestalA").x+Object.Position("PedestalB").x);
        local northern = (Object.Position(self).x<mid);
        local facing = vector(0.0,0.0,northern?90.0:270.0);
        Object.Teleport(self, Object.Position(self), facing);
    }
}
