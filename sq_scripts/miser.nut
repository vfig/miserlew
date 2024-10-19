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
            print("SEQUENCER> wait done.");
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
                print("SEQUENCER> stop.");
                return;
            case SequenceAction.Wait:
                local param = GetNextAction().tointeger();
                local s = param/1000.0;
                print("SEQUENCER> wait for "+s+" ...");
                SetOneShotTimer("SequencerWait", s);
                return;
            // Actions that keep looping:
            case SequenceAction.TurnOn:
                local who = GetNextAction().tostring();
                print("SEQUENCER> turn on '"+who+"'.");
                Link.BroadcastOnAllLinksData(self, "TurnOn", "ScriptParams", who);
                break;
            case SequenceAction.TurnOff:
                local who = GetNextAction().tostring();
                print("SEQUENCER> turn off '"+who+"'.");
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
            print("SEQUENCER> found name '"+data+"'");
        }
        local pattern = userparams().Sequence;
        pattern = pattern.tostring()+",";
        print("SEQUENCER> pattern: '"+pattern+"'");
        local seq = [];
        local start = 0;
        while(start<pattern.len()) {
            print("SEQUENCER>   start: "+start);
            local end = pattern.find(",", start);
            if (end==null)
                end = pattern.len();
            local bit = pattern.slice(start, end);
            print("SEQUENCER>   end: "+end);
            print("SEQUENCER>   bit: '"+bit+"'");
            start = end+1;
            local delay;
            try {
                delay = bit.tointeger();
            } catch(e) {
                delay = 0;
            }
            if (delay>0) {
                print("SEQUENCER>   > Wait("+delay+")");
                seq.push(SequenceAction.Wait);
                seq.push(delay);
            } else if (bit=="stop") {
                print("SEQUENCER>   > Stop()");
                seq.push(SequenceAction.Stop);
                break;
            } else {
                local off = (bit.slice(0,1)=="!");
                if (off)
                    bit = bit.slice(1);
                if (! (bit in names)) {
                    print("WARNING: Sequencer "+self+" has no ScriptParams link matching '"+bit+"'");
                }
                if (off)
                    print("SEQUENCER>   > TurOff("+bit+")");
                else
                    print("SEQUENCER>   > TurnOn("+bit+")");
                seq.push(off? SequenceAction.TurnOff:SequenceAction.TurnOn);
                seq.push(bit);
            }
        }
        if (seq.len()>0) {
            parsed_sequence = seq;
        } else {
            parsed_sequence = [SequenceAction.Stop];
        }
        print("SEQUENCER> Parsed sequence:");
        for (local i=0; i<parsed_sequence.len(); i++) {
            print("SEQUENCE>   "+i+": "+parsed_sequence[i]);
        }
        return parsed_sequence;
    }
}
