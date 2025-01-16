
Unit MenuDefs;

Interface

Uses Objects, Dialogs, Views, Drivers;

Type PServerConfigWindow =   ^TServerConfigWindow;
    TServerConfigWindow =   Object(TDialog)
        Constructor Init;
    End;
    PClientConfigWindow =   ^TClientConfigWindow;
    TClientConfigWindow =   Object(TDialog)
        Constructor Init;
    End;


Implementation

Function AddText(x,y:integer;V:PGroup;s:String):   PStaticText;

Var R:   TRect;
    P:   PStaticText;

Begin
    R.Assign(x,y,x+Length(s),y+1);
    p := New(PStaticText, Init(R, s));
    v^.Insert(p);
    AddText := p;
End;

Constructor TServerConfigWindow.Init;

Var R:   TRect;

Begin
    R.Assign(5,10,75,20);
    Inherited Init(R, 'Server Configuration');
End;

Constructor TClientConfigWindow.Init;

Var R:   TRect;

Begin
    R.Assign(6,11,76,21);
    Inherited Init(R, 'Client Configuration');
End;

End.
