const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const source = fs.readFileSync("js/app.js", "utf8");
const fresh = { id: "new", name: "Новое упражнение", muscle_group: "Ноги" };
const existing = { id: "old", name: "Старое упражнение", muscle_group: "Спина" };
const latest = { exercise_id: "old", exercises: existing, workouts: { performed_at: "2026-09-01" } };
let buttons = [], selected = null;
const context = {
  state: { exercises: [existing, fresh], exerciseId: null, dayExercises: [] },
  el: { search: { value: "" }, group: { value: "all" }, list: { innerHTML: "" } },
  latestByExercise: () => [latest], sortedHistory: () => [],
  changeLabel: () => ({ kind: "", icon: "check", text: "Прогресс" }),
  imageFor: () => "exercise.png", escapeHtml: String, muscleBadge: () => "",
  resultLabel: () => "20 × 10", dateLabel: () => "1 сент.",
  $$: () => buttons, latestFor: id => id === "old" ? latest : undefined,
  closeDetail: () => {}, openDrawer: () => {}, currentExercise: () => fresh,
  dayForGroup: () => "Ноги", selectRecordExercise: id => { selected = id; },
};
vm.createContext(context);
vm.runInContext(source.split(/\r?\n/).find(line => line.startsWith("function renderList()")), context);
context.renderList();
assert.match(context.el.list.innerHTML, /Новое упражнение/);
assert.match(context.el.list.innerHTML, /Нет записей/);
assert.match(context.el.list.innerHTML, /20 × 10/);
context.el.search.value = "новое";
context.renderList();
assert.match(context.el.list.innerHTML, /Новое упражнение/);
assert.doesNotMatch(context.el.list.innerHTML, /Старое упражнение/);
context.el.group.value = "Спина";
context.renderList();
assert.match(context.el.list.innerHTML, /Нет результатов/);
context.el.search.value = "";
context.el.group.value = "all";
buttons = [{ dataset: { exercise: "new" } }];
context.renderList();
buttons[0].onclick();
assert.equal(selected, "new");
assert.equal(context.state.recordDay, "Ноги");
console.log("PASS: exercises without sets, existing results, filters, first-set action");
