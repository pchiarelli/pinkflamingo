// Gera o "copia e cola" Pix (BR Code, padrão EMV do Banco Central).
// Sem dependências externas — é só montar os campos TLV + CRC16.

function tlv(id, value) {
  const len = value.length.toString().padStart(2, '0');
  return `${id}${len}${value}`;
}

// Remove acentos e caracteres fora do padrão, em maiúsculas.
function sanitize(str, max) {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^A-Za-z0-9 ]/g, '')
    .toUpperCase()
    .slice(0, max)
    .trim();
}

// CRC16/CCITT-FALSE (polinômio 0x1021, init 0xFFFF).
function crc16(payload) {
  let crc = 0xffff;
  for (let i = 0; i < payload.length; i++) {
    crc ^= payload.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

/// Monta o payload Pix. `amount` em número (reais); `txid` opcional.
export function buildPixPayload({ key, name, city, amount, txid = '***' }) {
  const merchantAccount = tlv('26',
    tlv('00', 'br.gov.bcb.pix') + tlv('01', key));
  const additional = tlv('62', tlv('05', sanitize(String(txid), 25) || '***'));

  let payload =
    tlv('00', '01') +                                   // formato
    merchantAccount +                                   // conta Pix
    tlv('52', '0000') +                                 // categoria
    tlv('53', '986') +                                  // moeda BRL
    (amount != null ? tlv('54', Number(amount).toFixed(2)) : '') +
    tlv('58', 'BR') +                                   // país
    tlv('59', sanitize(name, 25) || 'RECEBEDOR') +      // nome
    tlv('60', sanitize(city, 15) || 'CIDADE') +         // cidade
    additional;

  payload += '6304'; // ID + tamanho do CRC, antes de calcular
  return payload + crc16(payload);
}
