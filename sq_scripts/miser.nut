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
        Sound.PlayEnvSchema(self, "Event Reject, Operation FrobLock",
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
