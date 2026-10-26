# keepAwake: Slack post for friends

Attach: `../video/out/keepawake-lid-closed.mp4` (1080×1350, 29 s, works muted). Re-render with `npm run render:lid` in `marketing/video`.
Slack turns `*text*` into bold.

## English

> Nobody knew they needed this tool. Including me 😅
>
> Picture this: Claude Code is halfway through a refactor and you have to run to a meeting. You close the lid, laptop under your arm… and your agents *keep working*. The Mac doesn't fall asleep, the tests keep running, and when you're back the work is done instead of frozen where you left it.
>
> So I built *keepAwake*, a tiny Mac menu bar app:
> • *Connect Claude Code / Cursor* in one click: the Mac stays awake while the agent works and goes to sleep on its own when it's done
> • *Keep awake with lid closed*: keeps running with the lid shut, no external display needed
> • a plain timer too (15 min … 30 days, or Always) with a countdown in the menu bar
> • battery guard: turns itself off below 10%, so you don't come back to a dead laptop
>
> Free and open source: https://mikespineu.github.io/keepAwake/
>
> Under your arm is fine, in a backpack it's not, it'll cook 🔥 Let me know how it works for you!

## Polish

> Nikt nie wiedział, że potrzebuje takiego toola. Łącznie ze mną 😅
>
> Wyobraźcie sobie: Claude Code mieli wam refactor, a wy musicie lecieć na spotkanie. Zamykacie klapę, laptop pod pachę… i agenty *dalej działają*. Mac nie zasypia, testy lecą, a po powrocie robota jest skończona, a nie stoi w miejscu jak na wygaszaczu.
>
> Zrobiłem do tego *keepAwake*, małą apkę w pasku menu na Maca:
> • *Connect Claude Code / Cursor* jednym klikiem: Mac nie śpi, dopóki agent pracuje, i sam zasypia, kiedy skończy
> • *Keep awake with lid closed*: działa z zamkniętą klapą, bez zewnętrznego monitora
> • zwykły timer (15 min … 30 dni albo „Always”) z odliczaniem w pasku menu
> • battery guard: wyłącza się poniżej 10% baterii, żeby nie wrócić do trupa
>
> Darmowe i open source: https://mikespineu.github.io/keepAwake/
>
> Pod pachą spoko, w plecaku już nie, bo się ugotuje 🔥 Dajcie znać, jak u was działa!

## Facts behind it (keepAwake 1.2.0)

- Lid-closed mode is off by default. Turning it on the first time asks for the admin password once (a sudoers rule that only allows `pmset -a disablesleep 1/0`). It applies to agent holds too.
- When keepAwake stops (agent done, timer up, battery guard, Turn Off, Quit) with the lid closed, the Mac goes to sleep.
- The app itself shows "Don't put a running Mac in a bag — it can overheat." under the toggle, hence the backpack line.
