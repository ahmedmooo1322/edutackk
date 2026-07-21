export function success(res, data, status = 200) { return res.status(status).json({ success: true, data }); }
export function page(res, items, pagination) { return success(res, { items, pagination }); }

