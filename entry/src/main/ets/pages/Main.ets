import { HomePage } from './Home';
import { MedicineListPage } from './MedicineList';
import { PlanListPage } from './PlanList';
import { FamilyListPage } from './FamilyList';
import { MyPage } from './My';

/**
 * 主框架页：底部 Tab 导航，承载 5 个一级页面。
 *   Tab0 今日（HomePage）
 *   Tab1 药品（MedicineListPage）
 *   Tab2 计划（PlanListPage）
 *   Tab3 家属（FamilyListPage）
 *   Tab4 我的（MyPage）
 *
 * currentTab + refreshTick 两个状态驱动子页刷新：
 *   - onChange：切 Tab 时更新 currentTab 并 refreshTick++，触发当前 Tab 刷新
 *   - onPageShow：从二级页（新增药品/建计划/家属异常）返回时 refreshTick++，刷新当前 Tab
 */
@Entry
@Component
struct Main {
  @State currentTab: number = 0;
  @State refreshTick: number = 0;

  /**
   * 从二级页返回时触发，刷新当前 Tab。
   */
  onPageShow() {
    this.refreshTick++;
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage({ currentTab: this.currentTab, refreshTick: this.refreshTick })
      }
      .tabBar('今日')

      TabContent() {
        MedicineListPage({ currentTab: this.currentTab, refreshTick: this.refreshTick })
      }
      .tabBar('药品')

      TabContent() {
        PlanListPage({ currentTab: this.currentTab, refreshTick: this.refreshTick })
      }
      .tabBar('计划')

      TabContent() {
        FamilyListPage({ currentTab: this.currentTab, refreshTick: this.refreshTick })
      }
      .tabBar('家属')

      TabContent() {
        MyPage()
      }
      .tabBar('我的')
    }
    .barMode(BarMode.Fixed)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentTab = index;
      this.refreshTick++;
    })
    .width('100%')
    .height('100%')
  }
}
