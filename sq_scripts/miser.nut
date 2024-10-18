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
        print(""+self+" is not actually loot.");
    }
    // TODO: on begin script, change the texture
    //       on end script, change it back
    //       when a global trigger happens, remove M-NotActuallyLoot
}

/*
    BUGS:
        - first item picked up after "not treasure", if loot pile is selected,
          still gets combined into loot pile!!
            (i think this happens because M-NotActuallyLoot gets added back on
                to the loot stack in the inventory)
            (its okay, we only need two switches: into not-loot, at game start,
                and into loot after -- you will not have a loot stack in either case!)
            (alternatively, enumerate MetaProp links from SwitchTreasure to find
              concretes that are not contained by the player, and only add the
              metaprop onto them?)
        - replace textures are not copied over when a combine happens (see TBP solution)

    TODO:
        - add other texture info to design notes
        - swap textures!!

*/


class TreasureSwitcher extends SqRootScript {
    function OnSim() {
        // if (message().starting) {
        //     MakeLoot(false);
        // }
    }

    function OnTurnOn() {
        MakeLoot(true);
    }

    function OnTurnOff() {
        MakeLoot(false);
    }

    function MakeLoot(isLoot) {
        if (isLoot) {
            Object.RemoveMetaPropertyFromMany("M-NotActuallyLoot", "@M-NotActuallyLoot");
        } else {
            Object.AddMetaPropertyToMany("M-NotActuallyLoot", "@SwitchTreasure,-@M-NotActuallyLoot");
        }
    }
}
