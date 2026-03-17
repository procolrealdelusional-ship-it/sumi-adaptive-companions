type InputEvent = {
  focusScore?: number;
  actionMs?: number;
  actionFreq?: number;
  intent?: "yin" | "yang";
};

type InputEngine = {
  on(callback: (event: InputEvent) => void): void;
};

type KidsGuard = {
  begin(): void;
  remaining(): number;
};

type YinYangEngine = {
  getState(): { balance: number; energy: string };
  pushYin(): void;
  pushYang(): void;
  reportAction(ms: number, freq: number): void;
};

type IchimokuCloud = {
  getState(): { intensity: number; state: string };
  push(focusScore: number): void;
};

type QawwaliArc = {
  getState(): { phase: "drone" | "rhythm" | "build" | "peak" | "release" | "silence" };
};

export class NexoraEngine {
  constructor(
    private readonly guard: KidsGuard,
    private readonly input: InputEngine,
    private readonly yinyang: YinYangEngine,
    private readonly ichimoku: IchimokuCloud,
    private readonly qawwali: QawwaliArc,
  ) {}

  start() {
    this.guard.begin();
    this.input.on((event) => this.handleInput(event));
  }

  snapshot() {
    return {
      cloud: this.ichimoku.getState(),
      yinYang: this.yinyang.getState(),
      phase: this.qawwali.getState().phase,
      sessionExpired: this.guard.remaining() <= 0,
    };
  }

  private handleInput(event: InputEvent) {
    const focusScore = event.focusScore ?? 0;
    this.ichimoku.push(focusScore);

    if (event.intent === "yin") this.yinyang.pushYin();
    else if (event.intent === "yang") this.yinyang.pushYang();

    if (typeof event.actionMs === "number" && typeof event.actionFreq === "number") {
      this.yinyang.reportAction(event.actionMs, event.actionFreq);
    }
  }
}
