import { encode, type EncodeRequest } from './compress.ts';

let latest = 0;
let queue = Promise.resolve();

// one encode at a time; a job superseded while queued is skipped
onmessage = ({ data }: MessageEvent<EncodeRequest>) => {
  latest = data.job;
  queue = queue.then(async () => {
    if (data.job === latest) postMessage(await encode(data));
  });
};
