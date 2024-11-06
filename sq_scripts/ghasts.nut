class WineChoreography extends SqRootScript
{
    function SummonWine() {
        return Object.Create("CarriedWine");
    }

    function CarryWine(wine) {
        DetachWine(wine);
        Container.Add(wine, self, eDarkContainType.kContainTypeAlt);
    }

    function AttachWine(wine, elev, marker) {
        Container.Remove(wine);
        DetachWine(wine)
        Object.Teleport(wine, vector(), vector(), marker);
        local offset = Object.Position(marker)-Object.Position(elev);
        local link = Link.Create("PhysAttach", wine, elev);
        LinkTools.LinkSetData(link, "Offset", offset);
    }

    function DetachWine(wine) {
        local link = Link.GetOne("PhysAttach", wine);
        if (link!=0)
            Link.Destroy(link);
    }
}

class Clyde extends WineChoreography
{
    function OnCanGetWine_() {
        // TODO: check if we are carrying wine?
        Reply(true);
    }

    function OnGetWine() {
        // TODO: we need to pick up the wine if we dropped it somewhere!
        local wine = SummonWine();
        CarryWine(wine);
    }

    function OnPutWineOnElev() {
        local elevName = message().data;
        if (elevName==null || elevName=="")
            return;
        local markerName = message().data;
        if (markerName==null || markerName=="")
            return;
        local elev = Object.Named(elevName);
        local marker = Object.Named(markerName);
        if (elev==0 || marker==0) {
            print("ERROR: PutWineOnElev needs elevator name and marker name.");
            Reply(false);
            return;
        }
        // ?!?!?! what is 'wine'? we dont know!!
        AttachWine(wine, elev, marker)
    }
}

class ClydeFetchWine extends SqRootScript
{
    function OnTurnOn() {
        // We will start locked, and unlock once the big transition happens.
        // After that, we only ever want to fire the once, so lock again.
        if (Locked.IsLocked(self))
            return;
        print("Clyde!! Fetch me more wine!!!");
        SetProperty("Locked", true);
        local who = LinkDest(Link.GetOne("Population", self));
        local where = LinkDest(Link.GetOne("Route", self));
        if (who==0 || where==0) {
            print("ERROR: Who? Where?");
            return;
        }
        // Switch up patrol paths.
        Object.RemoveMetaProperty(who, "M-DoesPatrol");
        local link = Link.GetOne("AICurrentPatrol", who);
        if (link!=0)
            Link.Destroy(link);
        Link.Create("AICurrentPatrol", who, where);
        Object.AddMetaProperty(who, "M-DoesPatrol");
    }
}
