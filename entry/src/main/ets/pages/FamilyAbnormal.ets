import { promptAction, router } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { CollaborationSync } from '../common/CollaborationSync';
import { AbnormalEventVO, parseAbnormalEventList } from '../model/Family';
import { notificationTime } from '../model/Notification';
import { parseSimpleResult } from '../model/RemindTask';

/** 家属只处理自己获授权的异常；知晓和关闭均不代表已服药。 */
@Entry
@Component
struct FamilyAbnormal {
  @State eventList: AbnormalEventVO[] = [];
  @State loading: boolean = false;
  @State includeClosed: boolean = false;
  @State error: string = '';
  @State busyId: number = 0;
  @State refreshVersion: number = 0;
  private generation: number = 0;
  private visible: boolean = false;

  onPageShow() {
    this.visible = true;
    this.loadList();
  }

  onPageHide() {
    this.visible = false;
    this.generation++;
    this.loading = false;
    this.busyId = 0;
    this.eventList = [];
  }

  aboutToDisappear() {
    this.onPageHide();
  }

  async loadList() {
    if (!this.visible || this.loading || this.busyId !== 0) return;
    const ticket = ++this.generation;
    this.loading = true;
    this.error = '';
    this.eventList = [];
    try {
      await CollaborationSync.waitForPending();
      if (!this.visible || ticket !== this.generation) return;
      const result = parseAbnormalEventList(await HttpUtil.get(
        '/api/family/abnormal-events?includeClosed=' + this.includeClosed));
      if (!this.visible || ticket !== this.generation) return;
      if (result.code === 200) {
        this.eventList = result.data.slice();
        this.refreshVersion++;
      } else {
        this.error = result.message || '加载异常事件失败，请重试';
      }
    } catch (e) {
      if (!this.visible || ticket !== this.generation) return;
      this.error = '加载异常事件失败，请检查网络后重试';
    } finally {
      if (ticket === this.generation) this.loading = false;
    }
  }

  changeHistory() {
    if (this.busyId !== 0) return;
    this.includeClosed = !this.includeClosed;
    this.generation++;
    this.loading = false;
    this.loadList();
  }

  async act(event: AbnormalEventVO, close: boolean) {
    if (!this.visible || this.loading || this.busyId !== 0) return;
    this.busyId = event.id;
    const ticket = ++this.generation;
    this.error = '';
    try {
      if (close) {
        const answer = await promptAction.showDialog({
          title: '关闭这次协同？',
          message: '关闭后将移入历史记录。关闭协同不代表已确认服药，请先与被照护方核实情况。',
          buttons: [{ text: '取消', color: '#666666' }, { text: '确认关闭', color: '#0a59f7' }]
        });
        if (!this.visible || ticket !== this.generation || answer.index !== 1) return;
      }
      const result = parseSimpleResult(await CollaborationSync.post('/api/family/abnormal-events/' + event.id +
        (close ? '/close' : '/acknowledge')));
      if (!this.visible || ticket !== this.generation) return;
      if (result.code !== 200) {
        this.eventList = [];
        this.error = result.message || '操作失败，请刷新后重试';
        return;
      }
      this.busyId = 0;
      await this.loadList();
    } catch (e) {
      if (!this.visible || ticket !== this.generation) return;
      this.eventList = [];
      this.error = '操作未完成，请检查网络并刷新确认状态';
    } finally {
      if (ticket === this.generation) this.busyId = 0;
    }
  }

  typeText(type: string): string {
    if (type === 'UNCONFIRMED_TIMEOUT') return '超时未确认服药';
    if (type === 'CONSECUTIVE_UNCONFIRMED') return '连续多次未确认';
    if (type === 'PLAN_ENDED_UNFINISHED') return '计划结束未完成';
    return type;
  }

  statusText(status: string): string {
    if (status === 'OPEN') return '未处理';
    if (status === 'NOTIFIED') return '已通知';
    if (status === 'ACKNOWLEDGED') return '已知晓';
    if (status === 'CLOSED') return '已关闭';
    return status;
  }

  statusColor(status: string): string {
    if (status === 'OPEN') return '#ff3b30';
    if (status === 'NOTIFIED') return '#b86b00';
    if (status === 'ACKNOWLEDGED') return '#248a3d';
    return '#999999';
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('返回').height(44).fontSize(15).onClick(() => { router.back(); })
        Text('家属异常').fontSize(26).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('刷新').height(44).fontSize(15).enabled(!this.loading && this.busyId === 0)
          .onClick(() => { this.loadList(); })
      }.width('100%').margin({ top: 48 })

      Text('知晓表示已关注；关闭表示本次协同结束，均不代表已服药。')
        .fontSize(14).fontColor('#666666').width('100%')
      Button(this.includeClosed ? '已包含关闭历史 · 点击只看待协同' : '查看历史（包含已关闭）')
        .height(44).width('100%').fontSize(14).backgroundColor('#e8f1ff').fontColor('#0a59f7')
        .enabled(this.busyId === 0).onClick(() => { this.changeHistory(); })

      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#0a59f7')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.error !== '') {
        Column({ space: 16 }) {
          Text(this.error).fontSize(16).fontColor('#c32b25').textAlign(TextAlign.Center)
          Button('刷新重试').height(48).onClick(() => { this.loadList(); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.eventList.length === 0) {
        Column({ space: 8 }) {
          Text(this.includeClosed ? '暂无可查看的异常记录' : '暂无待协同异常').fontSize(16).fontColor('#999999')
          Text('仅显示当前授权范围内的异常，请结合实际情况了解用药。')
            .fontSize(14).fontColor('#999999').textAlign(TextAlign.Center)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.eventList, (event: AbnormalEventVO) => {
            ListItem() {
              Column({ space: 10 }) {
                Row({ space: 10 }) {
                  Text(event.userNickname || '被照护方').fontSize(17).fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                  Text(this.statusText(event.status)).fontSize(14).fontColor(this.statusColor(event.status))
                }.width('100%')
                Text((event.medicineName || '未知药品') + ' · ' + this.typeText(event.type))
                  .fontSize(16).fontColor('#333333').width('100%')
                Text('发生：' + notificationTime(event.occurredAt)).fontSize(13).fontColor('#777777').width('100%')
                if (event.scheduledAt) {
                  Text('计划：' + notificationTime(event.scheduledAt)).fontSize(13).fontColor('#777777').width('100%')
                }
                if (event.acknowledgedAt) {
                  Text('知晓：' + notificationTime(event.acknowledgedAt)).fontSize(13).fontColor('#777777').width('100%')
                }
                if (event.closedAt) {
                  Text('关闭：' + notificationTime(event.closedAt)).fontSize(13).fontColor('#777777').width('100%')
                }
                if (event.status === 'OPEN' || event.status === 'NOTIFIED') {
                  Button(this.busyId === event.id ? '正在处理…' : '我已知晓').height(48).width('100%')
                    .backgroundColor('#0a59f7').enabled(this.busyId === 0)
                    .onClick(() => { this.act(event, false); })
                } else if (event.status === 'ACKNOWLEDGED') {
                  Button(this.busyId === event.id ? '正在处理…' : '关闭本次协同').height(48).width('100%')
                    .backgroundColor('#e8f1ff').fontColor('#0a59f7').enabled(this.busyId === 0)
                    .onClick(() => { this.act(event, true); })
                }
              }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
                .backgroundColor('#f5f7fa').borderRadius(12)
            }
          }, (event: AbnormalEventVO) => event.id.toString() + '_' + this.refreshVersion)
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').padding({ left: 16, right: 16, bottom: 16 })
  }
}
