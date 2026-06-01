/**
 * Image OCR - Cloudflare Worker
 * 
 * 部署方式：
 * 1. 在 https://dash.cloudflare.com 创建 Worker
 * 2. 把此文件内容粘贴进去
 * 3. 部署后得到 URL 如：https://ocr-api.xxxx.workers.dev
 * 4. 在 index.html 中设置 WORKER_URL 为该地址
 * 
 * 可选 OCR 后端（在 wrangler.toml 或 Dashboard 设置环境变量）：
 * - OCR_API_PROVIDER: "ocrspace" (默认) 或 "google"
 * - OCR_API_KEY: 你的 API Key
 * 
 * OCR.space 注册：https://ocr.space/ (免费 500次/月)
 * Google Vision 注册：https://cloud.google.com/vision (免费 1000次/月)
 */

// 语言映射：Tesseract 代码 → OCR.space 代码
const LANG_MAP = {
  chi_sim: 'chs',
  eng:     'eng',
  jpn:     'jpn',
  kor:     'kor',
};

export default {
  async fetch(request, env) {
    // CORS 头
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // OPTIONS 预检
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: corsHeaders });
    }

    // 解析请求
    let body;
    try {
      body = await request.json();
    } catch {
      return new Response('Invalid JSON', { status: 400, headers: corsHeaders });
    }

    const { image, langs, filename } = body;
    if (!image) {
      return new Response('Missing "image" field (base64 data URL)', { status: 400, headers: corsHeaders });
    }

    // 提取 base64 数据
    const base64Data = image.includes(',') ? image.split(',')[1] : image;

    // 选择 OCR 后端
    const provider = env.OCR_API_PROVIDER || 'ocrspace';

    try {
      let text;

      if (provider === 'google') {
        text = await googleVision(base64Data, langs, env.OCR_API_KEY);
      } else {
        text = await ocrSpace(base64Data, langs, env.OCR_API_KEY);
      }

      return new Response(JSON.stringify({ success: true, text }), {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } catch (err) {
      return new Response(JSON.stringify({ success: false, error: err.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
  },
};

/**
 * OCR.space API
 * 免费：500 次/月，无需信用卡
 */
async function ocrSpace(base64, langs, apiKey) {
  const key = apiKey || 'helloworld'; // OCR.space 的公开测试 key，不保证稳定
  const ocrLang = langs
    .map(l => LANG_MAP[l])
    .filter(Boolean)
    .join(',');

  const formData = new FormData();
  formData.append('base64image', `data:image/png;base64,${base64}`);
  formData.append('language', ocrLang || 'eng');
  formData.append('OCREngine', '2');
  formData.append('scale', 'true');

  const resp = await fetch('https://api.ocr.space/parse/image', {
    method: 'POST',
    headers: { apikey: key },
    body: formData,
  });

  const data = await resp.json();

  if (!data.ParsedResults || data.ParsedResults.length === 0) {
    throw new Error(data.ErrorMessage?.[0]?.Message || 'OCR.space returned no results');
  }

  return data.ParsedResults
    .map(r => r.ParsedText)
    .filter(Boolean)
    .join('\n');
}

/**
 * Google Cloud Vision API
 * 需要：在 GCP 启用 Vision API，创建 API Key
 * 免费：1000 次/月
 */
async function googleVision(base64, langs, apiKey) {
  if (!apiKey) {
    throw new Error('Google Vision API key not configured. Set OCR_API_KEY env variable.');
  }

  // 语言映射：Tesseract 代码 → Google Vision 语言代码
  const googleLangMap = {
    chi_sim: 'zh-Hans',
    eng: 'en',
    jpn: 'ja',
    kor: 'ko',
  };

  const languageHints = langs
    .map(l => googleLangMap[l])
    .filter(Boolean);

  const payload = {
    requests: [{
      image: { content: base64 },
      features: [{ type: 'TEXT_DETECTION' }],
      imageContext: languageHints.length > 0 ? { languageHints } : undefined,
    }],
  };

  const resp = await fetch(
    `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }
  );

  const data = await resp.json();

  if (data.error) {
    throw new Error(data.error.message || 'Google Vision API error');
  }

  const annotations = data.responses?.[0]?.textAnnotations;
  if (!annotations || annotations.length === 0) {
    throw new Error('No text detected');
  }

  // 第一个元素是整块识别文本
  return annotations[0].description;
}
