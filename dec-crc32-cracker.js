/**DecCrc32Cracker
 * @createDate 2021-10-2

鸣谢
  文章：<https://moepus.oicp.net/2016/11/27/crccrack/> 作者：MoePus
  <https://github.com/ProgramRipper/crc32Cracker>
  <https://github.com/esterTion/BiliBili_crc2mid>
*/
; (function (root, factory) {
  typeof define == 'function' && define.amd ? define(factory) :
    typeof exports == 'object' && typeof module == 'object' ? module.exports = factory() :
      root.decCrc32Cracker = factory()
})(this || self, function () {
  "use strict";
  const { parseInt } = Number, isNum = (num) => typeof num === 'number'
  let table, fastMap, index
  const crc32 = (str) => {
    //if(typeof str!=='string'){str=String(str)}
    let crc = ~0, i
    for (i of str) {
      index = (crc ^ i.charCodeAt()) & 0xFF
      crc = crc >>> 8 ^ table[index]
    }
    return crc
  }
  const lastIndex = (crc) => {
    let i; for (i = 0; i < 256; i++) {
      if (crc === table[i] >>> 24) { return i }
    }
  }
  const getIndexes = (crc) => {
    let indexes = new Uint8Array(4), i, j, index, value
    for (i = 3, j = 0; j < 4; i--, j++) {
      index = indexes[j] = lastIndex(crc >>> (i << 3))
      value = table[index]
      crc ^= value >>> (j << 3)
    }
    return indexes
  }
  const check = (indexes, high, low) => {
    let crc = crc32(high)
    if (index !== indexes[3]) { return }
    let i, num; for (i = 2; i > -1; i--) {
      num = crc & 0xFF ^ indexes[i]
      if (num < 48 || num > 57) { return }
      low[i] = num - 48
      crc = crc >>> 8 ^ table[indexes[i]]
    }
    return low.reverse().join('')
  }
  return {
    init() {
      const POLY = 0xEDB88320
      table = new Uint32Array(256)
      let i, j, _; for (i = 0; i < 256; i++) {
        for (j = i, _ = 0; _ < 8; _++) {
          j = j & 1 ? j >>> 1 ^ POLY : j >>> 1
        }
        table[i] = j
      }
      fastMap = new Map()
      for (i = 0; i < 1000; i++) {
        fastMap.set(crc32(String(i)) >>> 0, i)
      }
    },
    get table() { return table },
    get fastMap() { return fastMap },
    crc32,
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
      const indexes = getIndexes(crc), _low = []
      let i, low; for (i = begin; i < end; i++) {
        low = check(indexes, String(i), _low)
        if (low != null) { yield i + '' + low }
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