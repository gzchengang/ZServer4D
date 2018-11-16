unit chatHomeFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts,
  CoreClasses, ZDBEngine, ZDBLocalManager, DoStatusIO, DataFrameEngine, PascalStrings,
  ListEngine, UnicodeMixedLib, MemoryStream64, zExpression, OpCode, xNATPhysics, NotifyObjectBase,
  CommunicationFramework, CommunicationFrameworkDoubleTunnelIO_NoAuth;

type
  // ��������ÿ�û�������ʵ����
  // �Զ�����û��洢��Ϣ��������
  // ���磬�Ա��ǳƣ���¼ʱ�䣬���Դ���
  TChatServer_UserSpecial = class(TPeerClientUserSpecial)
  public
    // ���Դ���
    talkCounter: Integer;
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;
    procedure Progress; override;
  end;

  TChatServer = class(TCommunicationFramework_DoubleTunnelService_NoAuth)
  protected
    procedure UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_NoAuth); override;
    procedure UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_NoAuth); override;
  public
    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
    procedure cmd_PushMsg(Sender: TPeerIO; InData: SystemString);

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;
  end;

  IMsgNotify = interface
    procedure OnMsg(InData: SystemString);
  end;

  TChatClient = class(TCommunicationFramework_DoubleTunnelClient_NoAuth)
  public
    MsgNotify: IMsgNotify;

    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);

    procedure cmd_OnMsg(Sender: TPeerIO; InData: SystemString);
    procedure PushMsg(msg: SystemString);

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;
  end;

  TForm3 = class(TForm, IMsgNotify, ICommunicationFrameworkVMInterface)
    Layout1: TLayout;
    Label1: TLabel;
    HostEdit: TEdit;
    connectButton: TButton;
    DisconnectButton: TButton;
    Memo1: TMemo;
    ChatHomeMasterCheckBox: TCheckBox;
    Label2: TLabel;
    Layout2: TLayout;
    Label3: TLabel;
    MyNameEdit: TEdit;
    Label4: TLabel;
    Layout3: TLayout;
    TalkInfoLabel: TLabel;
    TalkEdit: TEdit;
    SendButton: TButton;
    Label5: TLabel;
    PortEdit: TEdit;
    ServiceLayout: TLayout;
    Layout5: TLayout;
    Label6: TLabel;
    ListenBindEdit: TEdit;
    Label7: TLabel;
    ListenPortEdit: TEdit;
    Label8: TLabel;
    StartListenButton: TButton;
    ChatServiceInfoLabel: TLabel;
    Timer1: TTimer;
    DebugCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ChatHomeMasterCheckBoxChange(Sender: TObject);
    procedure StartListenButtonClick(Sender: TObject);
    procedure MyNameEditChangeTracking(Sender: TObject);
    procedure connectButtonClick(Sender: TObject);
    procedure DisconnectButtonClick(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
  private
    // ICommunicationFrameworkVMInterface
    procedure p2pVMTunnelAuth(Sender: TPeerIO; const Token: SystemString; var Accept: Boolean);
    procedure p2pVMTunnelOpenBefore(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
    procedure p2pVMTunnelOpen(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
    procedure p2pVMTunnelOpenAfter(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
    procedure p2pVMTunnelClose(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);

    // IMsgNotify
    procedure OnMsg(InData: SystemString);
  public
    { Public declarations }

    phyServer: TCommunicationFrameworkServer;
    phyClient: TCommunicationFrameworkClient;
    serv: TChatServer;
    cli: TChatClient;
    procedure backcall_DoStatus(AText: SystemString; const ID: Integer);
  end;

var
  Form3: TForm3;

implementation

{$R *.fmx}


constructor TChatServer_UserSpecial.Create(AOwner: TPeerIO);
begin
  inherited;
  talkCounter := 0;
end;

destructor TChatServer_UserSpecial.Destroy;
begin

  inherited;
end;

procedure TChatServer_UserSpecial.Progress;
begin
  inherited;

end;

procedure TChatServer.UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_NoAuth);
begin
  inherited;
  RecvTunnel.ProgressPeerIOP(procedure(P_IO: TPeerIO)
    var
      rDef: TPeerClientUserDefineForRecvTunnel_NoAuth;
    begin
      rDef := GetUserDefineRecvTunnel(P_IO);
      if rDef.LinkOk then
          rDef.SendTunnel.Owner.SendDirectConsoleCmd('OnMsg', Format(TimeToStr(Now) + ' unknow user out home.', []));
    end);
end;

procedure TChatServer.UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_NoAuth);
begin
  inherited;
  RecvTunnel.ProgressPeerIOP(procedure(P_IO: TPeerIO)
    var
      rDef: TPeerClientUserDefineForRecvTunnel_NoAuth;
    begin
      rDef := GetUserDefineRecvTunnel(P_IO);
      if rDef.LinkOk then
          rDef.SendTunnel.Owner.SendDirectConsoleCmd('OnMsg', Format(TimeToStr(Now) + ' unknow user in home.', []));
    end);
end;

constructor TChatServer.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
  ARecvTunnel.UserSpecialClass := TChatServer_UserSpecial;
end;

procedure TChatServer.cmd_PushMsg(Sender: TPeerIO; InData: SystemString);
var
  MyUserSpec: TChatServer_UserSpecial;
begin
  // ��˫ͨ���ı���У���Ҫ��ָ��ǰ�����linkOK���ж�
  // linkokҲ��ʾ��֤�ɹ���ֻ����֤�ɹ����û�����
  if not GetUserDefineRecvTunnel(Sender).LinkOk then
      exit;

  MyUserSpec := Sender.UserSpecial as TChatServer_UserSpecial;
  inc(MyUserSpec.talkCounter);

  RecvTunnel.ProgressPeerIOP(procedure(P_IO: TPeerIO)
    var
      rDef: TPeerClientUserDefineForRecvTunnel_NoAuth;
      PeerUserSpec: TChatServer_UserSpecial;
    begin
      rDef := GetUserDefineRecvTunnel(P_IO);

      // linkOK�ͱ�ʾ�Ѿ���¼��¼�ɹ���
      // ����Ǵ���֤��˫ͨ����linkokҲ��ʾ��֤�ɹ�
      // ��˫ͨ���ı���У���Ҫ��ָ��ǰ�����linkOK���ж�
      if rDef.LinkOk then
        begin
          PeerUserSpec := P_IO.UserSpecial as TChatServer_UserSpecial;

          rDef.SendTunnel.Owner.SendDirectConsoleCmd('OnMsg', InData);
        end;
    end);
end;

procedure TChatServer.RegisterCommand;
begin
  inherited;
  RecvTunnel.RegisterDirectConsole('PushMsg').OnExecute := cmd_PushMsg;
end;

procedure TChatServer.UnRegisterCommand;
begin
  inherited;
  RecvTunnel.UnRegisted('PushMsg');
end;

constructor TChatClient.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
end;

procedure TChatClient.cmd_OnMsg(Sender: TPeerIO; InData: SystemString);
begin
  // �����������У���ջ�ǲ��ȶ��ģ������ݵ�ʹ�ã�Ҫô����������Ҫôȫ�ֱ�����Ҫô�͸���
  // �����ջ���ȶ������ǰ���Ҫ�����ݸ��Ƴ���
  // ����������ǽ�InData���Ƶ�Data3��Ȼ���ú��÷�ʽ����OnMsg
  ProgressPost.PostExecuteP(0, procedure(Sender: TNPostExecute)
    begin
      MsgNotify.OnMsg(TimeToStr(Now) + ' ' + Sender.Data3);
    end).Data3 := InData;
end;

procedure TChatClient.PushMsg(msg: SystemString);
begin
  SendTunnel.SendDirectConsoleCmd('PushMsg', msg);
end;

procedure TChatClient.RegisterCommand;
begin
  inherited;
  RecvTunnel.RegisterDirectConsole('OnMsg').OnExecute := cmd_OnMsg;
end;

procedure TChatClient.UnRegisterCommand;
begin
  inherited;
  RecvTunnel.UnRegisted('OnMsg');
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, backcall_DoStatus);

  MyNameEditChangeTracking(MyNameEdit);
  ChatHomeMasterCheckBoxChange(ChatHomeMasterCheckBox);

  phyServer := TXPhysicsServer.Create.StableIO;
  phyServer.VMInterface := self;
  TCommunicationFramework_StableServer(phyServer).OfflineTimeout := 5 *  1000;

  phyClient := TXPhysicsClient.Create.StableIO;

  serv := TChatServer.Create(TCommunicationFrameworkWithP2PVM_Server.Create, TCommunicationFrameworkWithP2PVM_Server.Create);
  serv.RecvTunnel.StartService('::', 0);
  serv.SendTunnel.StartService('::', 1);
  serv.RegisterCommand;

  cli := TChatClient.Create(TCommunicationFrameworkWithP2PVM_Client.Create, TCommunicationFrameworkWithP2PVM_Client.Create);
  cli.MsgNotify := self;
  cli.RegisterCommand;
end;

procedure TForm3.Timer1Timer(Sender: TObject);
begin
  phyServer.Progress;
  phyClient.Progress;
  serv.Progress;
  cli.Progress;

  ChatServiceInfoLabel.Text := Format('Online Count: %d', [serv.TotalLinkCount]);
end;

procedure TForm3.ChatHomeMasterCheckBoxChange(Sender: TObject);
begin
  ServiceLayout.Visible := TCheckBox(Sender).IsChecked;
end;

procedure TForm3.StartListenButtonClick(Sender: TObject);
begin
  if TPascalString(TButton(Sender).Text).Exists('stop') then
    begin
      phyServer.StopService;
      TButton(Sender).Text := 'Start Listen';
    end
  else
    begin
      if not phyServer.StartService(ListenBindEdit.Text, umlStrToInt(ListenPortEdit.Text)) then
          RaiseInfo('listen service Failed');

      TButton(Sender).Text := 'Stop Listen';
    end;
end;

procedure TForm3.MyNameEditChangeTracking(Sender: TObject);
begin
  TalkInfoLabel.Text := Format('%s talk: ', [TEdit(Sender).Text]);
end;

procedure TForm3.connectButtonClick(Sender: TObject);
begin
  phyClient.AsyncConnectP(HostEdit.Text, umlStrToInt(PortEdit.Text), procedure(const cState: Boolean)
    begin
      phyClient.ClientIO.BuildP2PAuthTokenP(procedure
        begin
          DoStatus('wait open...');
          phyClient.ClientIO.OpenP2PVMTunnelP(True, '', procedure(const VMauthState: Boolean)
            begin
              if VMauthState then
                begin
                  phyClient.ClientIO.p2pVMTunnel.InstallLogicFramework(cli.SendTunnel);
                  phyClient.ClientIO.p2pVMTunnel.InstallLogicFramework(cli.RecvTunnel);

                  DoStatus('connection virtual adapter...');
                  cli.AsyncConnectP('::', 1, 0, procedure(const ccState: Boolean)
                    begin
                      if ccState then
                          cli.TunnelLinkP(procedure(const lState: Boolean)
                          begin
                            if lState then
                              begin
                                DoStatus('chat client connected!');
                                cli.PushMsg(Format('hello guys,im %s', [MyNameEdit.Text]));
                              end;
                          end);
                    end);
                end
              else
                begin
                  DoStatus('OpenP2PVMTunnelP failed...');
                end;
            end);
        end);
    end);
end;

procedure TForm3.DisconnectButtonClick(Sender: TObject);
begin
  phyClient.Disconnect;
end;

procedure TForm3.SendButtonClick(Sender: TObject);
begin
  cli.PushMsg(TalkInfoLabel.Text + TalkEdit.Text);
end;

procedure TForm3.p2pVMTunnelAuth(Sender: TPeerIO; const Token: SystemString; var Accept: Boolean);
begin
  Accept := True;
end;

procedure TForm3.p2pVMTunnelOpenBefore(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
begin
  Sender.p2pVM.InstallLogicFramework(serv.RecvTunnel);
  Sender.p2pVM.InstallLogicFramework(serv.SendTunnel);
end;

procedure TForm3.p2pVMTunnelOpen(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
begin

end;

procedure TForm3.p2pVMTunnelOpenAfter(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
begin

end;

procedure TForm3.p2pVMTunnelClose(Sender: TPeerIO; p2pVMTunnel: TCommunicationFrameworkWithP2PVM);
begin
  Sender.p2pVM.UnInstallLogicFramework(serv.RecvTunnel);
  Sender.p2pVM.UnInstallLogicFramework(serv.SendTunnel);
end;

procedure TForm3.OnMsg(InData: SystemString);
begin
  Memo1.Lines.Add(InData);
  Memo1.GoToTextEnd;
end;

procedure TForm3.backcall_DoStatus(AText: SystemString; const ID: Integer);
begin
  if not DebugCheckBox.IsChecked then
      exit;
  Memo1.Lines.Add(AText);
  Memo1.GoToTextEnd;
end;

end.