import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { Constants } from '../common/Constants';
import { HttpUtil } from '../common/HttpUtil';
import { FamilyRelationVO, parseFamilyRelationList, parseFamilyRelation } from '../model/Family';
import { InviteRequest, AcceptInviteRequest } from '../model/Request';

/**
 * 家属协同页。
 * 方向约定：owner = 被照护方（发起邀请），family = 家属（凭码接受）。
 * 同一个账号既可能是 owner 也可能是 family，页面按当前用户 id 判断视角渲染。
 */
@Entry
@Component
struct FamilyList {
  @State relationList: FamilyRelationVO[] = [];
  @State loading: boolean = true;
  @State refreshVersion: number = 0;
  @State myUserId: number = 0;

  // 两个操作面板的显隐
  @State showInvite: boolean = false;
  @State showAccept: boolean = false;

  // 表单字段
  @State relationType: string = '';    // 发起绑定的称谓（可选）
  @State inviteCodeInput: string = ''; // 接受邀请时输入的邀请码
  @State lastInviteCode: string = '';  // 最近生成的邀请码，高亮展示给家属

  async aboutToAppear() {
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      const uid = await prefs.get(Constants.KEY_USER_ID, 0) as number;
      this.myUserId = uid;
    } catch (e) {
      this.myUserId = 0;
    }
  }

  onPageShow() {
    this.loadList();
  }

  /**
   * 拉取家属关系列表。
   */
  async loadList() {
    try {
      const respStr = await HttpUtil.get('/api/family/relations');
      const result = parseFamilyRelationList(respStr);
      if (result.code === 200) {
        this.relationList = result.data.slice();
        this.refreshVersion++;
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载家属关系失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 判断当前用户是不是这条关系的 owner（被照护方）。
   */
  isOwner(rel: FamilyRelationVO): boolean {
    return rel.ownerUserId === this.myUserId;
  }

  /**
   * 对方昵称：我是 owner 就显示家属昵称，我是 family 就显示被照护方昵称。
   */
  otherNickname(rel: FamilyRelationVO): string {
    if (this.isOwner(rel)) {
      if (rel.familyUserId !== 0 && rel.familyNickname !== '') {
        return rel.familyNickname;
      }
      return '家属（待接受）';
    }
    if (rel.ownerNickname !== '') {
      return rel.ownerNickname;
    }
    return '被照护方';
  }

  /**
   * 关系状态转中文。
   */
  statusText(status: string): string {
    if (status === 'PENDING') return '待确认';
    if (status === 'ACTIVE') return '已生效';
    if (status === 'REJECTED') return '已拒绝';
    if (status === 'REVOKED') return '已解除';
    return status;
  }

  statusColor(status: string): string {
    if (status === 'ACTIVE') return '#34c759';
    if (status === 'PENDING') return '#ff9500';
    return '#999999';
  }

  /**
   * 安全取邀请码（后端可能返回 null）。
   */
  safeCode(rel: FamilyRelationVO): string {
    return rel.inviteCode ? rel.inviteCode : '';
  }

  /**
   * 发起绑定邀请（owner）。
   */
  async doInvite() {
    try {
      const req = new InviteRequest();
      req.relationType = this.relationType;
      const respStr = await HttpUtil.post('/api/family/invitations', req);
      const result = parseFamilyRelation(respStr);
      if (result.code === 200) {
        this.lastInviteCode = result.data.inviteCode;
        this.showInvite = false;
        promptAction.showToast({ message: '邀请码已生成' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '发起邀请失败，请重试' });
    }
  }

  /**
   * 接受绑定邀请（family）。
   */
  async doAccept() {
    if (this.inviteCodeInput === '') {
      promptAction.showToast({ message: '请输入邀请码' });
      return;
    }
    try {
      const req = new AcceptInviteRequest(this.inviteCodeInput);
      const respStr = await HttpUtil.post('/api/family/invitations/accept', req);
      const result = parseFamilyRelation(respStr);
      if (result.code === 200) {
        this.inviteCodeInput = '';
        this.showAccept = false;
        promptAction.showToast({ message: '绑定成功' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '接受邀请失败，请重试' });
    }
  }

  /**
   * 解除关系（owner 单方）。
   */
  async doUnbind(rel: FamilyRelationVO) {
    try {
      const respStr = await HttpUtil.delete('/api/family/relations/' + rel.id);
      const result = parseFamilyRelation(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '已解除关系' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '解除关系失败，请重试' });
    }
  }

  build() {
    Column() {
      // 标题
      Text('家属协同')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 16 })

      // 两个操作按钮
      Row({ space: 12 }) {
        Text('发起绑定')
          .fontSize(15)
          .fontColor(this.showInvite ? '#ffffff' : '#0a59f7')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor(this.showInvite ? '#0a59f7' : '#e8f1ff')
          .borderRadius(20)
          .onClick(() => {
            this.showInvite = !this.showInvite;
            this.showAccept = false;
          })

        Text('接受邀请')
          .fontSize(15)
          .fontColor(this.showAccept ? '#ffffff' : '#0a59f7')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor(this.showAccept ? '#0a59f7' : '#e8f1ff')
          .borderRadius(20)
          .onClick(() => {
            this.showAccept = !this.showAccept;
            this.showInvite = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 家属异常入口（家属视角查看被照护方异常）
      Row() {
        Text('查看被照护方异常')
          .fontSize(15)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('›')
          .fontSize(18)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .margin({ left: 16, right: 16, top: 12 })
      .backgroundColor('#f5f7fa')
      .borderRadius(12)
      .onClick(() => {
        router.pushUrl({ url: 'pages/FamilyAbnormal' });
      })

      // 发起绑定面板
      if (this.showInvite) {
        Column() {
          TextInput({ placeholder: '关系称谓（可选，如：父/母/子女）', text: this.relationType })
            .fontSize(15)
            .height(44)
            .onChange((value: string) => {
              this.relationType = value;
            })

          Button('生成邀请码')
            .fontSize(15)
            .width('100%')
            .height(44)
            .margin({ top: 10 })
            .backgroundColor('#0a59f7')
            .onClick(() => {
              this.doInvite();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 4 })
      }

      // 接受邀请面板
      if (this.showAccept) {
        Column() {
          TextInput({ placeholder: '输入家属给你的邀请码', text: this.inviteCodeInput })
            .fontSize(15)
            .height(44)
            .onChange((value: string) => {
              this.inviteCodeInput = value;
            })

          Button('接受绑定')
            .fontSize(15)
            .width('100%')
            .height(44)
            .margin({ top: 10 })
            .backgroundColor('#0a59f7')
            .onClick(() => {
              this.doAccept();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 4 })
      }

      // 最近生成的邀请码（高亮展示，方便抄给家属）
      if (this.lastInviteCode !== '') {
        Row() {
          Text('邀请码：' + this.lastInviteCode)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0a59f7')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 4 })
        .justifyContent(FlexAlign.Center)
      }

      // 关系列表
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#0a59f7')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.relationList.length === 0) {
        Column() {
          Text('还没有家属关系')
            .fontSize(16)
            .fontColor('#999999')
          Text('点击「发起绑定」生成邀请码，或「接受邀请」绑定家属')
            .fontSize(13)
            .fontColor('#bbbbbb')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.relationList, (rel: FamilyRelationVO) => {
            ListItem() {
              Column() {
                // 上半部分：昵称 + 称谓 + 状态
                Row() {
                  Column() {
                    Text(this.otherNickname(rel))
                      .fontSize(17)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                    Text(rel.relationType === '' ? '未标注关系' : rel.relationType)
                      .fontSize(13)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(this.statusText(rel.relationStatus))
                    .fontSize(12)
                    .fontColor(this.statusColor(rel.relationStatus))
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#f0f0f0')
                    .borderRadius(10)
                }
                .width('100%')

                // 待确认 + 我是 owner：显示邀请码
                if (rel.relationStatus === 'PENDING' && this.isOwner(rel) && this.safeCode(rel) !== '') {
                  Text('邀请码：' + this.safeCode(rel))
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#0a59f7')
                    .margin({ top: 10 })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                }

                // 我是 owner 且已生效：显示解绑按钮
                if (this.isOwner(rel) && rel.relationStatus === 'ACTIVE') {
                  Row({ space: 10 }) {
                    Button('解除关系')
                      .fontSize(13)
                      .height(32)
                      .backgroundColor('#ff3b30')
                      .onClick(() => {
                        this.doUnbind(rel);
                      })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.End)
                  .margin({ top: 12 })
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('#ffffff')
              .borderRadius(12)
            }
          }, (rel: FamilyRelationVO) => rel.id.toString() + '_' + this.refreshVersion.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}
