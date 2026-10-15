// Exercise actual page business methods with delayed HTTP responses, without rendering ArkUI.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const project = path.resolve(__dirname, '..');
const sdk = process.env.DEVECO_SDK_HOME || 'C:/Program Files/Huawei/DevEco Studio/sdk';
const ts = require(path.join(sdk, 'default/openharmony/ets/build-tools/ets-loader/node_modules/typescript/lib/typescript.js'));
const etsRoot = path.join(project, 'entry/src/main/ets');
const flush = () => new Promise(resolve => setImmediate(resolve));

function compile(source, globals) {
  const output = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020,
    module: ts.ModuleKind.CommonJS } }).outputText;
  const context = { module: { exports: {} }, exports: {}, ...globals };
  vm.runInNewContext(output, context);
  return context.module.exports;
}

function fixtures() {
  let complete;
  let reject;
  let unread = 1;
  let eventStatus = 'OPEN';
  let gets = 0;
  const mutation = new Promise((resolve, fail) => { complete = resolve; reject = fail; });
  const http = {
    post: () => mutation,
    get: async url => {
      gets++;
      if (url.includes('unread-count')) return JSON.stringify({ code: 200, data: unread });
      if (url.startsWith('/api/family/')) return JSON.stringify({ code: 200,
        data: eventStatus === 'CLOSED' ? [] : [{ id: 1, status: eventStatus }] });
      if (url.startsWith('/api/notifications?')) return JSON.stringify({ code: 200,
        data: { items: [], unreadCount: unread, hasMore: false, nextBeforeId: null } });
      return JSON.stringify({ code: 200, data: { id: 1, title: 'Test', content: 'Authorized' } });
    }
  };
  const syncFile = path.join(etsRoot, 'common/CollaborationSync.ets');
  const sync = fs.existsSync(syncFile) ? compile(fs.readFileSync(syncFile, 'utf8')
    .replace(/^import[\s\S]*?;\s*/gm, '') + '\nmodule.exports = CollaborationSync;', { HttpUtil: http }) : undefined;
  function page(name) {
    let source = fs.readFileSync(path.join(etsRoot, 'pages', name + '.ets'), 'utf8');
    const build = source.indexOf('\n  build()');
    assert.ok(build > 0, name + ' must have a build method');
    source = source.slice(0, build) + '\n}\nmodule.exports = ' + (name === 'My' ? 'MyPage' : name) + ';';
    source = source.replace(/^import[\s\S]*?;\s*/gm, '')
      .replace(/^\s*@(Entry|Component)\s*$/gm, '')
      .replace(/@(State|Prop)(\s+@Watch\('[^']*'\))?\s+/g, '')
      .replace(/\bstruct\b/g, 'class').replace(/\bexport\s+/g, '');
    return compile(source, { HttpUtil: http, CollaborationSync: sync,
      parseSimpleResult: JSON.parse, parseAbnormalEventList: JSON.parse,
      router: { getParams: () => ({ id: 1 }) },
      promptAction: { showDialog: async () => ({ index: 1 }) } });
  }
  return { page, complete: (code = 200) => complete(JSON.stringify({ code, message: 'test' })),
    reject: () => reject(new Error('network unavailable')),
    setUnread: value => { unread = value; }, setEvent: value => { eventStatus = value; },
    getCount: () => gets };
}

async function readAllAcrossInstances() {
  const f = fixtures();
  const Page = f.page('Notifications');
  const previous = new Page();
  previous.onPageShow(); await flush();
  const operation = previous.readAll();
  previous.onPageHide();
  const current = new Page();
  current.onPageShow(); await flush();
  f.setUnread(0); f.complete();
  await operation; await flush();
  assert.equal(current.unreadCount, 0, 'new inbox instance must wait for previous read-all');
}

async function familyActionAcrossInstances(close) {
  const f = fixtures();
  const Page = f.page('FamilyAbnormal');
  const previous = new Page();
  previous.onPageShow(); await flush();
  const operation = previous.act({ id: 1, status: close ? 'ACKNOWLEDGED' : 'OPEN' }, close);
  await flush();
  previous.onPageHide();
  const current = new Page();
  current.onPageShow(); await flush();
  f.setEvent(close ? 'CLOSED' : 'ACKNOWLEDGED'); f.complete();
  await operation; await flush();
  if (close) assert.equal(current.eventList.length, 0, 'new family page must not retain a closed event');
  else assert.equal(current.eventList[0].status, 'ACKNOWLEDGED', 'new family page must observe acknowledgement');
}

async function detailReadBeforeBadgeRefresh() {
  const f = fixtures();
  const Detail = f.page('NotificationDetail');
  const detail = new Detail();
  detail.visible = true;
  const operation = detail.load();
  await flush();
  detail.onPageHide();
  const My = f.page('My');
  const current = new My();
  const count = current.loadUnreadCount();
  await flush();
  f.setUnread(0); f.complete();
  await operation; await count; await flush();
  assert.equal(current.unreadCount, 0, 'badge must wait for the detail read operation');
  assert.equal(detail.message, null, 'hidden detail must not restore its content');
}

async function rejectedReadNeverShowsBody() {
  const f = fixtures();
  const Detail = f.page('NotificationDetail');
  const detail = new Detail();
  detail.visible = true;
  const operation = detail.load();
  await flush(); f.complete(403); await operation;
  assert.equal(detail.message, null, 'read403 must suppress successfully fetched body');
  assert.equal(detail.error, 'test');
}

async function rejectedMutationUnblocksNewPage() {
  const f = fixtures();
  const Page = f.page('Notifications');
  const previous = new Page();
  previous.onPageShow(); await flush();
  const operation = previous.readAll();
  const current = new Page();
  current.onPageShow(); await flush();
  assert.equal(f.getCount(), 1, 'new instance must wait even when a mutation will fail');
  f.reject();
  await operation; await flush();
  assert.equal(previous.error, '全部已读失败，请检查网络后重试', 'original caller must receive mutation rejection');
  assert.equal(current.loading, false, 'mutation rejection must release pending readers');
  assert.equal(current.unreadCount, 1, 'new instance must reload unchanged server state after a rejection');
  assert.equal(current.error, '', 'one failed mutation must not fail a later GET');
}

async function hiddenWaitersNeverFetch() {
  const f = fixtures();
  const Inbox = f.page('Notifications');
  const previous = new Inbox();
  previous.onPageShow(); await flush();
  const operation = previous.readAll();
  previous.onPageHide();
  const notifications = new Inbox();
  const Family = f.page('FamilyAbnormal');
  const family = new Family();
  const Detail = f.page('NotificationDetail');
  const detail = new Detail();
  const My = f.page('My');
  const my = new My();
  notifications.onPageShow(); family.onPageShow(); detail.onPageShow();
  const badge = my.loadUnreadCount();
  await flush();
  assert.equal(f.getCount(), 1, 'all readers must wait for the pending mutation');
  notifications.onPageHide(); family.onPageHide(); detail.onPageHide();
  my.pageVisible = false; my.onRefresh();
  f.complete();
  await operation; await badge; await flush();
  assert.equal(f.getCount(), 1, 'pages hidden during the wait must not issue a GET');
  assert.equal(detail.message, null, 'hidden detail must retain no body');
}

(async () => {
  const watchdog = setTimeout(() => {
    process.stderr.write('FAIL lifecycle verification timed out\n');
    process.exit(1);
  }, 5000);
  const cases = [readAllAcrossInstances, () => familyActionAcrossInstances(false),
    () => familyActionAcrossInstances(true), detailReadBeforeBadgeRefresh, rejectedReadNeverShowsBody,
    rejectedMutationUnblocksNewPage, hiddenWaitersNeverFetch];
  let failures = 0;
  for (let index = 0; index < cases.length; index++) {
    try { await cases[index](); process.stdout.write(`PASS lifecycle case ${index + 1}\n`); }
    catch (error) { failures++; process.stderr.write(`FAIL lifecycle case ${index + 1}: ${error.message}\n`); }
  }
  if (failures) process.exitCode = 1;
  clearTimeout(watchdog);
})();
