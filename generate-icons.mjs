import zlib from 'zlib'
import fs from 'fs'

const crcTable = new Uint32Array(256)
for (let n = 0; n < 256; n++) {
  let c = n
  for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1)
  crcTable[n] = c
}
function crc32(buf) {
  let crc = 0xFFFFFFFF
  for (let i = 0; i < buf.length; i++) crc = crcTable[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8)
  return (crc ^ 0xFFFFFFFF) >>> 0
}
function chunk(type, data) {
  const t = Buffer.from(type, 'ascii')
  const l = Buffer.allocUnsafe(4); l.writeUInt32BE(data.length, 0)
  const c = Buffer.allocUnsafe(4); c.writeUInt32BE(crc32(Buffer.concat([t, data])), 0)
  return Buffer.concat([l, t, data, c])
}

function inCircle(x, y, cx, cy, r) { return (x-cx)**2 + (y-cy)**2 <= r**2 }
function inRect(x, y, rx, ry, rw, rh) { return x >= rx && x <= rx+rw && y >= ry && y <= ry+rh }

function generateIcon(size) {
  const sig = Buffer.from([137,80,78,71,13,10,26,10])
  const ihdr = Buffer.allocUnsafe(13)
  ihdr.writeUInt32BE(size,0); ihdr.writeUInt32BE(size,4)
  ihdr[8]=8; ihdr[9]=6; ihdr[10]=0; ihdr[11]=0; ihdr[12]=0

  const cr = size * 0.22 // corner radius
  const cx = size / 2, cy = size / 2

  function inBg(x, y) {
    const l = cr, r = size-cr, t = cr, b = size-cr
    if (x>=l && x<=r) return true
    if (y>=t && y<=b) return true
    return inCircle(x,y,l,t,cr)||inCircle(x,y,r,t,cr)||inCircle(x,y,l,b,cr)||inCircle(x,y,r,b,cr)
  }

  // Dumbbell: two weight stacks + bar
  const bh = size*0.10, bw = size*0.50
  const wr = size*0.19
  const lx = size*0.27, rx2 = size*0.73

  function inDumbbell(x, y) {
    if (inRect(x,y, cx-bw/2, cy-bh/2, bw, bh)) return true
    // Weight plates (stacked rects)
    const pw = size*0.065, ph = size*0.38
    if (inRect(x,y, lx-pw/2, cy-ph/2, pw, ph)) return true
    if (inRect(x,y, lx-pw*1.7, cy-ph*0.75, pw, ph*0.75*2)) return true
    if (inRect(x,y, rx2-pw/2, cy-ph/2, pw, ph)) return true
    if (inRect(x,y, rx2+pw*0.7, cy-ph*0.75, pw, ph*0.75*2)) return true
    return false
  }

  const sl = 1 + size*4
  const raw = Buffer.allocUnsafe(size*sl)

  for (let y=0; y<size; y++) {
    raw[y*sl] = 0
    for (let x=0; x<size; x++) {
      const p = y*sl+1+x*4
      if (inBg(x,y)) {
        const d = Math.sqrt((x-cx)**2+(y-cy)**2)/(size*0.5)
        const t = Math.min(d,1)*0.75
        let r2 = Math.round(59*(1-t)+10*t)
        let g  = Math.round(130*(1-t)+14*t)
        let b  = Math.round(246*(1-t)+23*t)
        if (inDumbbell(x,y)) { r2=240; g=248; b=255 }
        raw[p]=Math.max(0,Math.min(255,r2))
        raw[p+1]=Math.max(0,Math.min(255,g))
        raw[p+2]=Math.max(0,Math.min(255,b))
        raw[p+3]=255
      } else {
        raw[p]=0; raw[p+1]=0; raw[p+2]=0; raw[p+3]=0
      }
    }
  }

  const comp = zlib.deflateSync(raw, { level: 1 })
  return Buffer.concat([sig, chunk('IHDR',ihdr), chunk('IDAT',comp), chunk('IEND',Buffer.alloc(0))])
}

fs.mkdirSync('public/icons', { recursive: true })
fs.writeFileSync('public/icons/icon-192.png', generateIcon(192))
fs.writeFileSync('public/icons/icon-512.png', generateIcon(512))

// Favicon SVG (emoji works fine in browser SVG)
fs.writeFileSync('public/favicon.svg', `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="22" fill="#0a0e17"/>
  <text y=".9em" font-size="85" font-family="Apple Color Emoji,Segoe UI Emoji,sans-serif">🏋️</text>
</svg>`)

console.log('✓ Icons generated')
