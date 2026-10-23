import { module, test } from 'qunit';
import { accepts, decodeText, splitForMiddle, stem } from '#src/lib/files.ts';

const png = { name: 'Photo.PNG', type: 'image/png' };
const wav = { name: 'take.wav', type: 'audio/wav' };

module('Unit | lib/files', function () {
	test('accepts reads an accept list', function (assert) {
		assert.true(accepts(png, 'image/*'));
		assert.false(accepts(wav, 'image/*'));
		assert.true(accepts(wav, 'image/*, .wav'));
		assert.true(accepts(png, '.png'));
		assert.true(accepts(wav, 'audio/wav'));
		assert.true(accepts(wav, ''), 'an empty list takes any file');
	});

	test('stem drops the extension only', function (assert) {
		assert.strictEqual(stem('scan.final.jpg'), 'scan.final');
		assert.strictEqual(stem('.env'), '.env');
		assert.strictEqual(stem('README'), 'README');
	});

	test('splitForMiddle keeps the tail whole', function (assert) {
		assert.deepEqual(splitForMiddle('short.txt', 9), [
			'',
			'short.txt',
		]);
		assert.deepEqual(splitForMiddle('a-long-name.wav', 8), [
			'a-long-',
			'name.wav',
		]);
	});

	test('decodeText detects the encoding', function (assert) {
		const utf8 = new TextEncoder().encode('Grüße');
		assert.strictEqual(decodeText(utf8), 'Grüße', 'UTF-8');
		assert.strictEqual(
			decodeText(
				new Uint8Array([
					0xff, 0xfe, 0x48, 0x00, 0x69, 0x00,
				]),
			),
			'Hi',
			'UTF-16LE by its byte order mark',
		);
		assert.strictEqual(
			decodeText(
				new Uint8Array([
					0xfe, 0xff, 0x00, 0x48, 0x00, 0x69,
				]),
			),
			'Hi',
			'UTF-16BE by its byte order mark',
		);
		assert.strictEqual(
			decodeText(
				new Uint8Array([0x47, 0x72, 0xfc, 0xdf, 0x65]),
			),
			'Grüße',
			'Windows-1252 when not UTF-8',
		);
	});
});
