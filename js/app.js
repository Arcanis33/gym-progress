const config = window.GYM_CONFIG ?? {};
const configured =
  config.SUPABASE_URL &&
  config.SUPABASE_ANON_KEY &&
  !config.SUPABASE_URL.includes("YOUR_PROJECT") &&
  !config.SUPABASE_ANON_KEY.includes("YOUR_SUPABASE");

const elements = {
  setup: document.querySelector("#setup-screen"),
  auth: document.querySelector("#auth-screen"),
  app: document.querySelector("#app-screen"),
  authForm: document.querySelector("#auth-form"),
  authMessage: document.querySelector("#auth-message"),
  signOut: document.querySelector("#sign-out-button"),
  workoutForm: document.querySelector("#workout-form"),
  workoutMessage: document.querySelector("#workout-message"),
  performedAt: document.querySelector("#performed-at"),
  notes: document.querySelector("#workout-notes"),
  setRows: document.querySelector("#set-rows"),
  setTemplate: document.querySelector("#set-row-template"),
  addSet: document.querySelector("#add-set-button"),
  addExercise: document.querySelector("#add-exercise-button"),
  cancelEdit: document.querySelector("#cancel-edit-button"),
  editorTitle: document.querySelector("#editor-title"),
  saveWorkout: document.querySelector("#save-workout-button"),
  refresh: document.querySelector("#refresh-button"),
  history: document.querySelector("#history"),
  exerciseDialog: document.querySelector("#exercise-dialog"),
  exerciseForm: document.querySelector("#exercise-form"),
  exerciseMessage: document.querySelector("#exercise-message"),
};

const state = { exercises: [], workouts: [], editingWorkoutId: null, charts: [] };
let db;

function showOnly(name) {
  elements.setup.classList.toggle("hidden", name !== "setup");
  elements.auth.classList.toggle("hidden", name !== "auth");
  elements.app.classList.toggle("hidden", name !== "app");
  elements.signOut.classList.toggle("hidden", name !== "app");
}

function setMessage(element, text = "", error = false) {
  element.textContent = text;
  element.classList.toggle("error", error);
}

function setBusy(button, busy) {
  button.disabled = busy;
  button.setAttribute("aria-busy", String(busy));
}

function localDateTimeValue(date = new Date()) {
  const shifted = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return shifted.toISOString().slice(0, 16);
}

function formatDate(value) {
  return new Intl.DateTimeFormat("ru-RU", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

function formatNumber(value, maximumFractionDigits = 1) {
  return new Intl.NumberFormat("ru-RU", { maximumFractionDigits }).format(value || 0);
}

function escapeHtml(value = "") {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function exerciseOptions(selectedId = "") {
  return state.exercises
    .map((exercise) => `<option value="${exercise.id}" ${exercise.id === selectedId ? "selected" : ""}>${escapeHtml(exercise.name)}</option>`)
    .join("");
}

function addSetRow(set = {}) {
  const fragment = elements.setTemplate.content.cloneNode(true);
  const row = fragment.querySelector("tr");
  const exercise = row.querySelector(".set-exercise");
  exercise.innerHTML = `<option value="">Выберите…</option>${exerciseOptions(set.exercise_id)}`;
  row.querySelector(".set-weight").value = set.weight_kg ?? "";
  row.querySelector(".set-reps").value = set.reps ?? "";
  row.querySelector(".set-rpe").value = set.rpe ?? "";
  row.querySelector(".set-warmup").checked = Boolean(set.is_warmup);
  row.querySelector(".remove-set").addEventListener("click", () => {
    row.remove();
    if (!elements.setRows.children.length) addSetRow();
  });
  elements.setRows.append(fragment);
}

function resetEditor() {
  state.editingWorkoutId = null;
  elements.editorTitle.textContent = "Новая тренировка";
  elements.saveWorkout.textContent = "Сохранить тренировку";
  elements.cancelEdit.classList.add("hidden");
  elements.workoutForm.reset();
  elements.performedAt.value = localDateTimeValue();
  elements.setRows.replaceChildren();
  addSetRow();
  setMessage(elements.workoutMessage);
}

function readSets() {
  return [...elements.setRows.querySelectorAll("tr")].map((row, index) => ({
    exercise_id: row.querySelector(".set-exercise").value,
    set_order: index + 1,
    weight_kg: Number(row.querySelector(".set-weight").value),
    reps: Number(row.querySelector(".set-reps").value),
    rpe: row.querySelector(".set-rpe").value ? Number(row.querySelector(".set-rpe").value) : null,
    is_warmup: row.querySelector(".set-warmup").checked,
  }));
}

async function loadData() {
  setBusy(elements.refresh, true);
  const [exerciseResult, workoutResult] = await Promise.all([
    db.from("exercises").select("id,name,muscle_group").order("name"),
    db
      .from("workouts")
      .select("id,performed_at,notes,workout_sets(id,exercise_id,set_order,weight_kg,reps,rpe,is_warmup,exercises(id,name))")
      .order("performed_at", { ascending: false }),
  ]);
  setBusy(elements.refresh, false);
  if (exerciseResult.error) throw exerciseResult.error;
  if (workoutResult.error) throw workoutResult.error;
  state.exercises = exerciseResult.data ?? [];
  state.workouts = (workoutResult.data ?? []).map((workout) => ({
    ...workout,
    workout_sets: [...workout.workout_sets].sort((a, b) => a.set_order - b.set_order),
  }));
  render();
}

async function saveWorkout(event) {
  event.preventDefault();
  const sets = readSets();
  if (!sets.length || sets.some((set) => !set.exercise_id || !set.reps || Number.isNaN(set.weight_kg))) {
    setMessage(elements.workoutMessage, "Заполните данные каждого подхода.", true);
    return;
  }

  setBusy(elements.saveWorkout, true);
  setMessage(elements.workoutMessage, "Сохраняю…");
  const workoutPayload = {
    performed_at: new Date(elements.performedAt.value).toISOString(),
    notes: elements.notes.value.trim() || null,
  };

  let workoutId = state.editingWorkoutId;
  let error;
  if (workoutId) {
    ({ error } = await db.from("workouts").update(workoutPayload).eq("id", workoutId));
    if (!error) ({ error } = await db.from("workout_sets").delete().eq("workout_id", workoutId));
  } else {
    const result = await db.from("workouts").insert(workoutPayload).select("id").single();
    error = result.error;
    workoutId = result.data?.id;
  }

  if (!error) {
    ({ error } = await db.from("workout_sets").insert(sets.map((set) => ({ ...set, workout_id: workoutId }))));
  }

  setBusy(elements.saveWorkout, false);
  if (error) {
    setMessage(elements.workoutMessage, `Не удалось сохранить: ${error.message}`, true);
    return;
  }
  resetEditor();
  await loadData();
}

function editWorkout(id) {
  const workout = state.workouts.find((item) => item.id === id);
  if (!workout) return;
  state.editingWorkoutId = id;
  elements.editorTitle.textContent = "Редактирование тренировки";
  elements.saveWorkout.textContent = "Сохранить изменения";
  elements.cancelEdit.classList.remove("hidden");
  elements.performedAt.value = localDateTimeValue(new Date(workout.performed_at));
  elements.notes.value = workout.notes ?? "";
  elements.setRows.replaceChildren();
  workout.workout_sets.forEach(addSetRow);
  document.querySelector("#workout-form").scrollIntoView({ behavior: "smooth", block: "start" });
}

async function deleteWorkout(id) {
  if (!window.confirm("Удалить тренировку и все её подходы?")) return;
  const { error } = await db.from("workouts").delete().eq("id", id);
  if (error) {
    window.alert(`Не удалось удалить: ${error.message}`);
    return;
  }
  if (state.editingWorkoutId === id) resetEditor();
  await loadData();
}

async function saveExercise(event) {
  event.preventDefault();
  const submitter = event.submitter;
  if (submitter?.value === "cancel") {
    elements.exerciseDialog.close();
    return;
  }
  const name = document.querySelector("#exercise-name").value.trim();
  if (!name) return;
  setBusy(document.querySelector("#save-exercise-button"), true);
  const { data, error } = await db
    .from("exercises")
    .insert({ name, muscle_group: document.querySelector("#muscle-group").value.trim() || null })
    .select("id,name,muscle_group")
    .single();
  setBusy(document.querySelector("#save-exercise-button"), false);
  if (error) {
    setMessage(elements.exerciseMessage, error.code === "23505" ? "Такое упражнение уже существует." : error.message, true);
    return;
  }
  state.exercises.push(data);
  state.exercises.sort((a, b) => a.name.localeCompare(b.name, "ru"));
  elements.exerciseForm.reset();
  elements.exerciseDialog.close();
  [...elements.setRows.querySelectorAll(".set-exercise")].forEach((select) => {
    const previous = select.value;
    select.innerHTML = `<option value="">Выберите…</option>${exerciseOptions(previous)}`;
  });
}

function calculations() {
  const workingSets = state.workouts.flatMap((workout) => workout.workout_sets.filter((set) => !set.is_warmup));
  const volume = workingSets.reduce((sum, set) => sum + Number(set.weight_kg) * set.reps, 0);
  const e1rm = workingSets.reduce((best, set) => Math.max(best, Number(set.weight_kg) * (1 + set.reps / 30)), 0);
  return { workingSets, volume, e1rm };
}

function renderStats() {
  const { workingSets, volume, e1rm } = calculations();
  document.querySelector("#stat-workouts").textContent = state.workouts.length;
  document.querySelector("#stat-sets").textContent = workingSets.length;
  document.querySelector("#stat-volume").textContent = `${formatNumber(volume, 0)} кг`;
  document.querySelector("#stat-e1rm").textContent = `${formatNumber(e1rm)} кг`;
}

function renderHistory() {
  if (!state.workouts.length) {
    elements.history.innerHTML = '<p class="empty">Пока нет тренировок. Добавьте первую выше.</p>';
    return;
  }
  elements.history.innerHTML = state.workouts.map((workout) => `
    <article class="workout-card">
      <div class="workout-card-header">
        <div>
          <h3>${formatDate(workout.performed_at)}</h3>
          ${workout.notes ? `<p>${escapeHtml(workout.notes)}</p>` : ""}
        </div>
        <div class="workout-actions">
          <button class="secondary edit-workout" data-id="${workout.id}" type="button">Изменить</button>
          <button class="danger delete-workout" data-id="${workout.id}" type="button">Удалить</button>
        </div>
      </div>
      <ul>${workout.workout_sets.map((set) => `<li>${escapeHtml(set.exercises?.name ?? "Упражнение")} — ${formatNumber(Number(set.weight_kg), 2)} кг × ${set.reps}${set.rpe ? `, RPE ${set.rpe}` : ""}${set.is_warmup ? " (разминка)" : ""}</li>`).join("")}</ul>
    </article>`).join("");
  elements.history.querySelectorAll(".edit-workout").forEach((button) => button.addEventListener("click", () => editWorkout(button.dataset.id)));
  elements.history.querySelectorAll(".delete-workout").forEach((button) => button.addEventListener("click", () => deleteWorkout(button.dataset.id)));
}

function renderCharts() {
  state.charts.forEach((chart) => chart.destroy());
  state.charts = [];
  const chronological = [...state.workouts].reverse();
  const labels = chronological.map((workout) => new Intl.DateTimeFormat("ru-RU", { day: "2-digit", month: "short" }).format(new Date(workout.performed_at)));
  const volumeData = chronological.map((workout) => workout.workout_sets.filter((set) => !set.is_warmup).reduce((sum, set) => sum + Number(set.weight_kg) * set.reps, 0));
  const e1rmData = chronological.map((workout) => workout.workout_sets.filter((set) => !set.is_warmup).reduce((best, set) => Math.max(best, Number(set.weight_kg) * (1 + set.reps / 30)), 0));
  const common = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } };
  state.charts.push(new window.Chart(document.querySelector("#volume-chart"), {
    type: "bar",
    data: { labels, datasets: [{ data: volumeData, backgroundColor: "#6ca17d" }] },
    options: common,
  }));
  state.charts.push(new window.Chart(document.querySelector("#e1rm-chart"), {
    type: "line",
    data: { labels, datasets: [{ data: e1rmData, borderColor: "#28663f", backgroundColor: "#28663f", tension: .25 }] },
    options: common,
  }));
}

function render() {
  renderStats();
  renderHistory();
  renderCharts();
}

async function handleSession(session) {
  if (!session) {
    showOnly("auth");
    return;
  }
  showOnly("app");
  resetEditor();
  try {
    await loadData();
  } catch (error) {
    setMessage(elements.workoutMessage, `Ошибка загрузки: ${error.message}`, true);
  }
}

async function init() {
  if (!configured || !window.supabase) {
    showOnly("setup");
    return;
  }
  db = window.supabase.createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY);
  const { data } = await db.auth.getSession();
  await handleSession(data.session);
  db.auth.onAuthStateChange((_event, session) => handleSession(session));

  elements.authForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = event.currentTarget.querySelector("button");
    setBusy(button, true);
    const { error } = await db.auth.signInWithOtp({
      email: document.querySelector("#email").value,
      options: { emailRedirectTo: `${window.location.origin}${window.location.pathname}` },
    });
    setBusy(button, false);
    setMessage(elements.authMessage, error ? error.message : "Ссылка отправлена. Проверьте почту.", Boolean(error));
  });
  elements.signOut.addEventListener("click", () => db.auth.signOut());
  elements.workoutForm.addEventListener("submit", saveWorkout);
  elements.addSet.addEventListener("click", () => addSetRow());
  elements.cancelEdit.addEventListener("click", resetEditor);
  elements.refresh.addEventListener("click", () => loadData().catch((error) => window.alert(error.message)));
  elements.addExercise.addEventListener("click", () => {
    setMessage(elements.exerciseMessage);
    elements.exerciseDialog.showModal();
  });
  elements.exerciseForm.addEventListener("submit", saveExercise);
}

init().catch((error) => {
  console.error(error);
  showOnly("setup");
  elements.setup.insertAdjacentHTML("beforeend", `<p class="message error">${escapeHtml(error.message)}</p>`);
});
