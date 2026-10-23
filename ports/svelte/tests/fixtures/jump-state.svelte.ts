export class JumpState {
	open = $state(true);
	picks: number[] = [];
	closes = 0;
	pick = (index: number) => this.picks.push(index);
	close = () => {
		this.open = false;
		this.closes += 1;
	};
}
