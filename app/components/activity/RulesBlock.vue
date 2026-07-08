<script setup lang="ts">
const { list } = useActivityTypes()
const { CYBER_POINT_GENITIVE } = useFormatPoints()
const settings = useActivitySettingsStore()

const mounted = useClientMounted()
const showRates = computed(() => mounted.value && settings.hasLoaded)
const expanded = ref(false)

const twinExample = computed(() => {
  const base = list.value.find((t) => t.twinBonusEnabled)?.points ?? 3
  const perTwin = Math.round(base * 0.2 * 10) / 10
  const total = Math.round((base + perTwin * 2) * 10) / 10
  return { base, perTwin, total }
})

function toggleDetails() {
  expanded.value = !expanded.value
}
</script>

<template>
  <GlowCard
    tone="violet"
    class="space-y-4"
  >
    <div class="flex items-center gap-2">
      <CyberPointIcon size="md" />
      <h3 class="font-display text-lg text-cyan-100">
        Правила
      </h3>
    </div>

    <div class="space-y-3 text-sm text-slate-300/90 leading-relaxed">
      <p>
        За участь у кланових активностях адміністрація нараховує
        <strong class="text-slate-200 font-medium">Cyber-кредити</strong>
        <CyberPointIcon
          size="xs"
          class="inline-block align-[-2px] mx-0.5"
        />.
        Їх можна обмінювати на нагороди зі складу клану. Заявку можна подати
        лише якщо вистачає Cyber-кредитів; якщо нагороди зараз немає на складі
        — можна встати в чергу, видача відбувається за порядком подачі.
      </p>

      <ul class="space-y-1.5 list-none pl-0">
        <li class="flex gap-2">
          <span class="text-cyan-400/80 shrink-0">→</span>
          <span>
            <strong class="text-slate-200 font-medium">Баланс</strong> — зверху
            кабінету; скільки Cyber-кредитів у вас на рахунку. Частина може бути
            «зайнята» активними заявками до видачі нагороди.
          </span>
        </li>
        <li class="flex gap-2">
          <span class="text-cyan-400/80 shrink-0">→</span>
          <span>
            <strong class="text-slate-200 font-medium">Нагороди</strong> — виберіть
            предмет і подайте заявку; без достатніх Cyber-кредитів заявку не
            приймуть. Списання — лише після видачі адміном.
          </span>
        </li>
        <li class="flex gap-2">
          <span class="text-cyan-400/80 shrink-0">→</span>
          <span>
            <strong class="text-slate-200 font-medium">Історія</strong> — усі
            нарахування, списання та видачі зберігаються назавжди.
          </span>
        </li>
      </ul>
    </div>

    <div>
      <div class="text-xs uppercase tracking-widest text-slate-500 mb-2">
        Поточні ставки за івент
      </div>
      <div class="flex flex-wrap gap-2">
        <template v-if="showRates">
          <span
            v-for="t in list"
            :key="t.type"
            class="badge text-xs inline-flex items-center gap-1.5"
            :class="t.accent"
          >
            <span>{{ t.emoji }} {{ t.label }} —</span>
            <CyberPoints
              :value="t.points"
              icon-size="xs"
            />
            <span
              v-if="t.twinBonusEnabled"
              class="opacity-70"
            >· +20% твінк</span>
          </span>
        </template>
        <template v-else>
          <span
            v-for="i in 4"
            :key="i"
            class="badge text-xs opacity-40"
          >···</span>
        </template>
      </div>
      <p class="mt-2 text-[11px] text-slate-500">
        Ставки можуть змінюватись — на майбутні івенти. Вже нараховані
        {{ CYBER_POINT_GENITIVE.toLowerCase() }} не перераховуються.
      </p>
    </div>

    <button
      type="button"
      class="inline-flex items-center gap-2 text-sm text-cyan-300/90 hover:text-cyan-200 transition-colors"
      :aria-expanded="expanded"
      @click="toggleDetails"
    >
      <span>{{ expanded ? 'Згорнути' : 'Докладніше' }}</span>
      <span class="text-[10px] opacity-70">{{ expanded ? '▲' : '▼' }}</span>
    </button>

    <div
      v-if="expanded && mounted"
      class="space-y-5 pt-1 border-t border-white/5 animate-fade-in text-sm text-slate-300/90 leading-relaxed"
    >
      <section class="space-y-2">
        <h4 class="font-display text-sm text-cyan-100 flex items-center gap-2">
          <CyberPointIcon size="xs" />
          <span>Як нараховуються Cyber-кредити</span>
        </h4>
        <p>
          Після кланової активності адміністратор створює івент і відмічає
          учасників. Кожному нараховується фіксована сума — вона одразу
          зберігається в базі та додається до вашого балансу. Сума може бути
          дробовою (наприклад,
          <CyberPoints
            :value="3.4"
            icon-size="xs"
            class="inline-flex align-middle mx-0.5"
          />).
        </p>
        <p>
          Якщо завтра змінять ставки в правилах — це вплине лише на
          <em class="text-slate-200 not-italic">нові</em> івенти. Те, що вже
          нараховано або списано, залишається без змін: баланс, історія та
          рейтинг за минулі періоди не перераховуються.
        </p>
      </section>

      <section class="space-y-2">
        <h4 class="font-display text-sm text-cyan-100">
          Де що подивитись у кабінеті
        </h4>
        <ul class="space-y-2 list-none pl-0">
          <li class="rounded-lg border border-white/5 bg-ink-900/40 px-3 py-2">
            <span class="text-slate-100 font-medium">Картки зверху</span>
            — баланс Cyber-кредитів, місце в рейтингу, нарахування за поточний
            місяць і кількість відвіданих івентів.
          </li>
          <li class="rounded-lg border border-white/5 bg-ink-900/40 px-3 py-2">
            <span class="text-slate-100 font-medium">Вкладка «Нагороди»</span>
            — склад клану: ціна в Cyber-кредитах, наявність, кнопка заявки.
            Якщо товару немає, але кредитів достатньо — «В чергу»; якщо не
            вистачає — заявку подати не можна.
          </li>
          <li class="rounded-lg border border-white/5 bg-ink-900/40 px-3 py-2">
            <span class="text-slate-100 font-medium">«Мої заявки»</span>
            — ваші активні та опрацьовані заявки з ціною на момент подачі та
            позицією в черзі.
          </li>
          <li class="rounded-lg border border-white/5 bg-ink-900/40 px-3 py-2">
            <span class="text-slate-100 font-medium">«Рейтинг»</span>
            — таблиця гравців за місяць і загалом; можна розгорнути твінки
            інших учасників.
          </li>
          <li class="rounded-lg border border-white/5 bg-ink-900/40 px-3 py-2">
            <span class="text-slate-100 font-medium">«Історія»</span>
            — повний журнал: нарахування (з позначками основного / твінків),
            заявки, списання та видачі нагород.
          </li>
        </ul>
      </section>

      <section class="space-y-2">
        <h4 class="font-display text-sm text-cyan-100">
          Як подати заявку на нагороду
        </h4>
        <ol class="space-y-1.5 list-decimal list-inside marker:text-cyan-400/70">
          <li>Відкрийте вкладку «Нагороди» і оберіть предмет.</li>
          <li>
            На картці нагороди перевірте, чи вистачає Cyber-кредитів. Якщо вже є
            інша заявка — її ціна тимчасово «займає» частину балансу, тому на
            нову заявку залишається менше. З рахунку знімають не одразу, а лише
            коли адмін видасть нагороду.
          </li>
          <li>
            Якщо предмет є на складі — «Запросити»; якщо немає — «В чергу».
            У «Моїх заявках» буде видно ваше місце в черзі (#1, #2…).
          </li>
          <li>
            Коли адмін видасть нагороду — Cyber-кредити спишуться за ціною з
            моменту заявки (навіть якщо ціну на складі потім змінять), дія
            потрапить в історію.
          </li>
        </ol>
      </section>

      <section class="space-y-2">
        <h4 class="font-display text-sm text-cyan-100 flex items-center gap-2">
          <span>👥</span>
          <span>Твінки (альтернативні персонажі)</span>
        </h4>
        <p>
          Твінк — це ваш додатковий персонаж у грі (не основний). Додати або
          змінити список можна у блоці «Мої твінки» нижче на цій сторінці.
          Ніки мають відповідати персонажам у грі — адмін бачить їх при
          нарахуванні.
        </p>
        <div class="rounded-lg border border-cyan-400/20 bg-cyan-500/5 px-3 py-2.5 space-y-2">
          <p class="text-slate-200 font-medium text-[13px]">
            Як рахується бонус за твінків
          </p>
          <ul class="space-y-1 list-none pl-0 text-[13px]">
            <li class="flex gap-2 items-center flex-wrap">
              <span class="text-cyan-300 shrink-0">★</span>
              <span>
                <strong class="text-slate-200">Основний персонаж</strong> —
                100% базової ставки івенту (наприклад,
              </span>
              <CyberPoints
                :value="twinExample.base"
                icon-size="xs"
              />).
            </li>
            <li class="flex gap-2">
              <span class="text-slate-400 shrink-0">◦</span>
              <span>
                <strong class="text-slate-200">Кожен твінк</strong> —
                додатково +20% від бази (можна обрати кілька).
              </span>
            </li>
            <li class="flex gap-2">
              <span class="text-slate-400 shrink-0">◦</span>
              <span>
                Можна нарахувати <strong class="text-slate-200">лише твінків</strong>
                без основного — якщо основний не брав участі.
              </span>
            </li>
          </ul>
          <p class="text-[12px] text-slate-400 border-t border-white/5 pt-2 flex flex-wrap items-center gap-x-1 gap-y-1">
            <span>Приклад: база</span>
            <CyberPoints
              :value="twinExample.base"
              icon-size="xs"
            />
            <span>, основний + 2 твінки =</span>
            <CyberPoints
              :value="twinExample.base"
              icon-size="xs"
            />
            <span>+ 2 ×</span>
            <CyberPoints
              :value="twinExample.perTwin"
              icon-size="xs"
            />
            <span>=</span>
            <CyberPoints
              :value="twinExample.total"
              icon-size="xs"
              class="text-cyan-200"
            />
            <span>— сума фіксується в історії і не зміниться, якщо правила оновлять пізніше.</span>
          </p>
        </div>
        <p class="text-[13px] text-slate-400">
          Бонус за твінків діє лише для типів івентів, де він увімкнений
          (позначено «+20% твінк» на бейджах вище). Адмін обирає учасників і
          відповідних твінків під час створення івенту.
        </p>
      </section>

      <section class="space-y-2">
        <h4 class="font-display text-sm text-cyan-100">
          Коротко
        </h4>
        <p class="text-[13px] text-slate-400">
          Cyber-кредити — валюта активності клану. Нараховує адмін, витрачаєте
          на нагороди через заявки. Усе прозоро: баланс, рейтинг і історія
          доступні в кабінеті. Питання — до адміністрації клану.
        </p>
      </section>
    </div>
  </GlowCard>
</template>
