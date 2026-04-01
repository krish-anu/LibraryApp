import { syncOverdueLoanFines } from './lib/fines';
syncOverdueLoanFines().then(()=>console.log('Success')).catch(e=>console.error('Error:', e));
