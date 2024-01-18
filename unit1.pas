unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Math, fpExprPars,
  lcltype, TAGraph, TAChartUtils,TASeries, TADrawUtils;

const maxsingle=9.9E10;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonCalcInterval: TButton;
    ButtonGraph: TButton;
    ButtonGraph1: TButton;
    Chart1: TChart;
    Chart1ConstantLine1: TConstantLine;
    Chart1ConstantLine2: TConstantLine;
    Editf: TEdit;
    EditPas: TEdit;
    EditYmax: TEdit;
    Editxmin: TEdit;
    Editxmax: TEdit;
    Editymin: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Panel1: TPanel;
    Panelchart: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    SaveDialog1: TSaveDialog;
    procedure ButtonCalcIntervalClick(Sender: TObject);
    procedure ButtonGraph1Click(Sender: TObject);
    procedure ButtonGraphClick(Sender: TObject);
    procedure Chart1AfterDraw(ASender: TChart; ADrawer: IChartDrawer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    graphclik:boolean;
    fparser: TFPExpressionParser;
    pas:integer;
    argument: TFPExprIdentifierDef;
    //enveloppe utilisateur
    xminu,xmaxu:double;
    yminu,ymaxu:double;
    function isdefined(x:double):boolean;
    function CheckVal(msg:boolean;s:string;var x:double):boolean;
    procedure calculbornesy(p:integer;x1,x2:double; var y1,y2:double);
    function arrondi(x:double;lg:word):string;
    procedure Tracer_Repere(X1,X2,Y1,Y2:double);
    procedure Tracer(p:integer;X1,X2,Y1,Y2:double);
    function DoublePoint(x,y:double):TDoublePoint;

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.CheckVal(msg:boolean;s:string;var x:double):boolean;
begin
   if not trystrtofloat(s,x) then
      begin
         if msg then MessageDlg(s+' n''est pas une valeur correcte',mtwarning,[mbok],0);
         exit;
      end;
   result:=true;
end;

function TForm1.isdefined(x:double):boolean;
begin
   result:=(abs(x)>=maxsingle) or (abs(x)=infinity) or (IsNan(x));

end;

procedure TForm1.FormCreate(Sender: TObject);
var x1,x2,y1,y2:double;
begin
   DefaultFormatSettings.DecimalSeparator := '.';
   FParser := TFPExpressionParser.Create(nil);
   pas:=5*screen.Width;
   EditPas.Text:=inttostr(pas);
   if  CheckVal(false,EditXmin.Text,x1) and CheckVal(false,EditXmax.Text,x2)
   and CheckVal(false,EditYmin.Text,y1) and CheckVal(false,EditYmax.Text,y2) then
      tracer_repere(x1,x2,y1,y2);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
     pas:=5*screen.Width;
     EditPas.Text:=inttostr(pas);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FParser.Free;
  closeaction:=cafree;
end;


procedure Tform1.calculbornesy(p:integer;x1,x2:double; var y1,y2:double);
var start,ok:boolean;
f,f0,x,step:double;
begin
   step:=abs(x2-x1)/p;
   start:=true;
   //start : first calculating, at this step no value is known
   x:=x1;
   while (x<=x2+step/2) do                              //be sure that last value of x is calculated
      begin
        argument.Asfloat := x;                             // Set the function argument value
        try
           ok:=true;
           f0 := FParser.Evaluate.ResFloat;                    // Calculate the function value in temp variable f0
           if  isdefined(f0) then
              ok:=false                                        //if ok, store in f
           else f:=f0;
        except
           ok:=false;
        end;
        if ok then f:=f0;
        if (start=true) or (f<y1) then y1:=f;
        if (start=true) or (f>y2) then y2:=f;
        start:=false;
        x:=x+step;
      end;
end;

procedure TForm1.ButtonCalcIntervalClick(Sender: TObject);
var x1,x2,y1,y2:double;
begin
   if not trystrtoint(editpas.text,pas) then
      begin
         MessageDlg('Pas='+editpas.Text+' n''est pas une valeur correcte',mtwarning,[mbok],0);
         exit;
      end;
   if pas<=0 then
      begin
         MessageDlg('Pas='+inttostr(pas)+' n''est pas une valeur correcte',mtwarning,[mbok],0);
         exit;
      end;
   if  not CheckVal(true,EditXmin.Text,x1) or not CheckVal(true,EditXmax.Text,x2) then exit;

   if trim(editf.text)='' then
      begin
         MessageDlg('Expression de la fonction manquante',mtwarning,[mbok],0);
         exit;
      end;
  // Enable the use of mathematical expressions
  FParser.BuiltIns := [bcMath];
  // Add the function argument
  FParser.Identifiers.Clear;
  argument := FParser.Identifiers.AddFloatVariable('x', 0.0);
  // Define the function, using the argument name x as defined above
  Try
      FParser.Expression := lowercase(editf.text);
   Except on E:Exception do
      begin
        MessageDlg('Expression de la fonction incorrecte',mtwarning,[mbok],0);
        exit;
      end;
   end;
   calculbornesy(pas,x1,x2,y1,y2);
   EditYmin.Text:=arrondi(Y1,2);
   EditYmax.Text:=arrondi(Y2,2);
   Tracer_Repere(X1,X2,Y1,Y2);
end;



procedure TForm1.ButtonGraph1Click(Sender: TObject);
var
  lRect: TRect;
  lFormBitmap: Graphics.TBitmap;
  j:TJPEGImage;
begin
  savedialog1.filename:='graph2d.jpg';
   if savedialog1.execute then
      begin
         if fileexists(savedialog1.filename) then DeleteFile(savedialog1.filename);
         lRect := PanelChart.ClientRect;
         lFormBitmap := Graphics.TBitmap.Create;
         try
            lFormBitmap.Width := PanelChart.ClientWidth;
            lFormBitmap.Height := PanelChart.ClientHeight;
            lFormBitmap.Canvas.CopyRect( Rect(0,0,lFormBitmap.Width-1,lFormBitmap.Height-1), PanelChart.Canvas,lRect);
            j := TJPEGImage.Create;
            try
              j.Assign(lFormBitmap);
              j.CompressionQuality:=90;
              j.savetofile(savedialog1.filename);
            finally
              j.free;
            end;
         finally
           lFormBitmap.Free;
         end;
      end;
end;

procedure TForm1.ButtonGraphClick(Sender: TObject);
var x1,x2,y1,y2:double;
begin
   if not trystrtoint(editpas.text,pas) then
      begin
         MessageDlg('Pas='+editpas.Text+' n''est pas une valeur correcte',mtwarning,[mbok],0);
         exit;
      end;
   if pas<=0 then
      begin
         MessageDlg('Pas='+inttostr(pas)+' n''est pas une valeur correcte',mtwarning,[mbok],0);
         exit;
      end;
   if  not CheckVal(true,EditXmin.Text,x1) or not CheckVal(true,EditXmax.Text,x2)
   or  not CheckVal(true,EditYmin.Text,y1) or not CheckVal(true,EditYmax.Text,y2) then exit;

   if trim(editf.text)='' then
      begin
         MessageDlg('Expression de la fonction manquante',mtwarning,[mbok],0);
         exit;
      end;
  // Enable the use of mathematical expressions
  FParser.BuiltIns := [bcMath];
  // Add the function argument
  FParser.Identifiers.Clear;
  argument := FParser.Identifiers.AddFloatVariable('x', 0.0);
  // Define the function, using the argument name x as defined above
  Try
      FParser.Expression := lowercase(editf.text);
   Except on E:Exception do
      begin
        MessageDlg('Expression de la fonction incorrecte',mtwarning,[mbok],0);
        exit;
      end;
   end;
   //Tracer
   xminu:=x1;
   xmaxu:=x2;
   yminu:=y1;
   ymaxu:=y2;
   graphclik:=true;
   Tracer_Repere(x1,x2,y1,y2);
end;

procedure TForm1.Chart1AfterDraw(ASender: TChart; ADrawer: IChartDrawer);
begin
  if graphclik then Tracer(pas,xminu,xmaxu,yminu,ymaxu);
end;


//arrondir une valeur pour qu'elle soit facilement compréhensible par l'humain
function Tform1.arrondi(x:double;lg:word):string;
const MAXEXP=5;
var s,d,expos:string;
    i,t,te:integer;
    y:double;

begin
  if x=trunc(x) then
     begin
        result:=floattostrf(x,fffixed,24,lg);
        exit;
     end;

   //(1) mettre en string au format exposant pour trouver E
   s:=floattostrf(x,ffExponent,24,lg+1);
   t:=pos('E',uppercase(s));
   //te est l'exposant
   trystrtoint(copy(s,t+1,length(s)-t),te);

   //(2) 2 cas possibles pour l'affichage final:
   //affichage sera en mode fixe et l'arrondi se fait sur la totalité
   //ou affichage final sera en mode exposant et l'arrondi se fait sur la partie devant l'exposant

   //(2a) arrondi sur la totalité (l'affichage ne se fera pas en exposant)
   if (te>=-1*lg) and (te<=MAXEXP) then
      begin
         s:=floattostrf(x,fffixed,24,lg+1);
         //si je n'ai pas de décimales j'en veux quand même et exactement un nombre lg
         t:=pos('.',s);
         if t=0 then
            begin
               s:=s+'.';
               t:=length(s)+1;
            end;
         for i:=length(s)-t to lg do s:=s+'0';
         //partie décimale
         d:=copy(s,t+1,length(s)-t);
         trystrtofloat(d,y);
         for i:=lg+1 to length(d) do y:=y/10;
         if y<=round(y) then y:=round(y)
         else y:=trunc(y)+1;
         result:=copy(s,1,t)+floattostr(y);
         exit;
      end
   //(2b) : on garde l'écriture exposant sinon et l'arrondi est sur ce qui est devant
   else
      begin
         trystrtofloat(copy(s,1,t-1),y);
         expos:=copy(s,t,length(s)-t+1);
         result:=arrondi(y,lg)+expos;
      end;
end;


procedure Tform1.Tracer_Repere(X1,X2,Y1,Y2:double);
begin
   Chart1.Extent.UseXMax := True;
   Chart1.Extent.UseXMin := True;
   Chart1.Extent.UseYMax := True;
   Chart1.Extent.UseYMin := True;
   //ajouter 1% (1/100ième) de marge autour
   Chart1.Extent.Xmin:=X1-abs(X2-X1)/100;
   Chart1.Extent.Xmax:=X2+abs(X2-X1)/100;
   Chart1.Extent.Ymin:=Y1-abs(Y2-Y1)/50;
   Chart1.Extent.Ymax:=Y2+abs(Y2-Y1)/50;

end;


function TForm1.DoublePoint(x,y:double):TDoublePoint;
begin
   Result.x:=x;
   Result.y:=y;
end;


procedure Tform1.Tracer(p:integer;x1,x2,y1,y2:double);
var x,f,f0,step:double;
    ok,okprev:boolean;
    Point:Tpoint;
begin
  //couleur  taille et transparence de la courbe
  chart1.Canvas.Pen.Width:=2;
  chart1.Canvas.Pen.style:=psSolid;
  chart1.Canvas.Pen.color:=clred;
  //la courbe est au-dessus du reste
  chart1.Canvas.Pen.Mode:=pmMask;

  //Tracer de courbe
  okprev:=true;
  step:=abs(x2-x1)/p;
  x:=x1;
  while (x<=x2+step/2) do                              //be sure that last value of x is calculated
     begin
        argument.AsFloat := x;                             // Set the function argument value
        try
           ok:=true;
           f0 := FParser.Evaluate.ResFloat;                    // Calculate the function value in temp variable f0
           if  isdefined(f0) then
              ok:=false                                        //if ok, store in f
           else f:=f0;
        except
           ok:=false;
        end;
        if ok then
           begin
              Point := Chart1.GraphToImage(DoublePoint(x, f));
              if okprev and (x>x1) then Chart1.Canvas.lineto(Point.x,Point.y)
              else
                Chart1.Canvas.moveto(Point.x,Point.y);       //premier point ou valeur indéfinie on se positionne
           end;
        x:=x+step;
        okprev:=ok;
     end;
end;



end.

