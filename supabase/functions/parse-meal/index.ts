const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization) throw new Error("Нужно войти в приложение");

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const authResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { Authorization: authorization, apikey: anonKey },
    });
    if (!authResponse.ok) return json({ error: "Сессия недействительна" }, 401);

    const { text } = await request.json();
    if (typeof text !== "string" || !text.trim() || text.length > 600) {
      return json({ error: "Введите описание порции длиной до 600 символов" }, 400);
    }

    const apiKey = Deno.env.get("OPENROUTER_API_KEY");
    if (!apiKey) return json({ error: "OpenRouter пока не настроен" }, 503);
    const model = Deno.env.get("OPENROUTER_MODEL") || "openrouter/free";
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://arcanis33.github.io/gym-progress/",
        "X-Title": "Gym Progress Nutrition",
      },
      body: JSON.stringify({
        model,
        temperature: 0,
        messages: [
          { role: "system", content: "Ты преобразуешь описание еды в JSON. Верни только объект вида {\"items\":[{\"name\":\"название продукта по-русски\",\"grams\":число,\"kcal_per_100g\":число или null,\"protein_per_100g\":число или null,\"fat_per_100g\":число или null,\"carbs_per_100g\":число или null}]}. Переноси пищевую ценность только когда пользователь явно указал её в тексте; не придумывай калории или БЖУ. Например, из «50 г йогурта, 30 ккал на 100 г» извлеки 50 г и 30 ккал на 100 г. Если указаны штуки, оцени массу съедобной части в граммах. Не добавляй продукты, которых нет в тексте. Готовые крупы и макароны считай варёными, если пользователь не уточнил иное." },
          { role: "user", content: text.trim() },
        ],
      }),
    });
    if (!response.ok) throw new Error(`OpenRouter: ${response.status}`);
    const payload = await response.json();
    const content = payload?.choices?.[0]?.message?.content || "";
    const parsed = JSON.parse(content.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, ""));
    const optionalNumber = (value: unknown) => value === null || value === undefined || value === "" ? null : Math.max(0, Number(value) || 0);
    const items = Array.isArray(parsed.items) ? parsed.items.slice(0, 20).map((item: Record<string, unknown>) => ({
      name: String(item.name || "").slice(0, 120),
      grams: Math.max(0, Math.min(10000, Number(item.grams) || 0)),
      kcal_per_100g: optionalNumber(item.kcal_per_100g),
      protein_per_100g: optionalNumber(item.protein_per_100g),
      fat_per_100g: optionalNumber(item.fat_per_100g),
      carbs_per_100g: optionalNumber(item.carbs_per_100g),
    })).filter((item: { name: string; grams: number }) => item.name && item.grams) : [];
    return json({ items });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Не удалось разобрать запрос" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}
