/**DecCrc32CrackerWasm
 * @createDate 2021-10-2

鸣谢
  文章：<https://moepus.oicp.net/2016/11/27/crccrack/> 作者：MoePus
  <https://github.com/ProgramRipper/crc32Cracker>
  <https://github.com/esterTion/BiliBili_crc2mid>
*/
; (function (root, factory) {
  typeof define == 'function' && define.amd ? define(factory) :
    typeof exports == 'object' && typeof module == 'object' ? module.exports = factory() :
      root.decCrc32CrackerWasm = factory()
})(this || self, function () {
  "use strict";
  let wasmUrl = 'data:application/wasm;base64,AGFzbQEAAAABEwNgAX8Bf2ACf38Bf2ADf39/AX8DBwYAAAABAAIFAwEAEQYJAX8BQYCAwAALB0MGBm1lbW9yeQIABGluaXQAAApnZXRJbmRleGVzAAEJY3JjMzJfZGVjAAIKY2hlY2tJbmRleAADCWZpbmRJbmRleAAFCvQFBnYBA39BACEBAkADQCABQYACRg0BQQghAiABIQMCQANAIAJFDQFBACADQQFxayAAcSADQQF2cyEDIAJBf2ohAgwACwsgA0EYdkGAiMCAAGogAToAACABQQJ0QYCAwIAAaiADNgIAIAFBAWohAQwACwtBgIDAgAALkgEBBH8jgICAgABBEGsiASSAgICAAEEAIQICQANAIAEgAkEfcSICOgAPIAJBA0sNASACQYCKwIAAaiAAIAJBA3QiA0F/c0EYcXZBgIjAgABqLQAAIgQ6AAAgBEECdEGAgMCAAGooAgAgA3YgAHMhACACQQFqIQIMAAsLQQAoAoCKwIAAIQIgAUEQaiSAgICAACACC7QBAQV/QQkhAUEKIQIDQCACQX9qIgJB/wFxQYSKwIAAaiAAQQpuIgNB9gFsIABqQTByOgAAIAEiBEF/aiEBIABBCUshBSADIQAgBQ0ACyAEQf8BcSIBQXZqIQAgAUGEisCAAGohAkF/IQECQANAIABFDQFBACACLQAAIAFzIgM6AI6KwIAAIANB/wFxQQJ0QYCAwIAAaigCACABQQh2cyEBIABBAWohACACQQFqIQIMAAsLIAELFQBBACABNgKAisCAACAAEISAgIAAC88BAQZ/I4CAgIAAQRBrIgEkgICAgAAgABCCgICAACEAQX8hAgJAQQAtAI6KwIAAQQAtAIOKwIAARw0AIAFBADsBDkF/IQJBAiEDA0AgA0H/AXEiBEGAisCAAGotAAAiBSAAcyIGQUZqQf8BcUH2AUkNASABIAEvAQ5BBHQgBkFQakH/AXFyQf8fcTsBDgJAIAQNACABLwEOQf8fcSECDAILIAVBAnRBgIDAgABqKAIAIABBCHZzIQAgA0F/aiEDDAALCyABQRBqJICAgIAAIAILSgBBACAANgKAisCAACACIAEgAiABShshAkF/IQADfwJAAkAgAiABRg0AIAEQhICAgABBf0wNASABIQALIAAPCyABQQFqIQEMAAsL'
  let ready, module, exports, table, fastMap
  let getIndexes, findIndex, checkIndex
  let onready = (result) => {
    !({ module, instance: { exports } } = result)
    !({ getIndexes, findIndex, checkIndex } = exports)
    const { memory, init, crc32_dec } = exports
    table = new Uint32Array(memory.buffer, init(0xEDB88320), 256)
    fastMap = new Map()
    let i; for (i = 0; i < 1000; i++) {
      fastMap.set(crc32_dec(i) >>> 0, i)
    }
  }
  const { parseInt } = Number, isNum = (num) => typeof num === 'number'
  return {
    init() {
      if (ready == null) {
        ready = WebAssembly.instantiateStreaming(fetch(wasmUrl)).then(onready)
        wasmUrl = onready = null
      }
      return ready
    },
    get module() { return module },
    get exports() { return exports },
    get table() { return table },
    get fastMap() { return fastMap },
    *xfilter(crc, begin, end) {
      //0-1999999999
      if (!isNum(crc)) { crc = parseInt(crc, 16) }
      if (!isNum(begin)) { begin = 0; end = 2000000 }
      if (!isNum(end)) { end = begin + 1 }
      crc = ~crc >>> 0
      if (begin === 0 && fastMap.has(crc)) {
        yield String(fastMap.get(crc))
        begin = 1
      }
      const indexes = getIndexes(crc) >>> 0
      let i; for (i = begin; i < end; i++) {
        i = findIndex(indexes, i, end)
        if (i < 0) break
        yield i + '' + checkIndex(i, indexes).toString(16).padStart(3, '0')
      }
    },
    find(crc, begin, end) {
      for (let i of this.xfilter(crc, begin, end)) { return i }
    },
    filter(crc, begin, end) {
      return Array.from(this.xfilter(crc, begin, end))
    }
  }
})