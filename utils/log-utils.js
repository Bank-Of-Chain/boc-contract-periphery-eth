/**
 * Printing Progress
 * @param {number} value Progress
 */
function logPercent(value) {
    const progress = Math.round(value / 2)
    const array = ['|', ...Array.apply(null, Array(progress)).map(() => '*'), ...Array.apply(null, Array(50 - progress)).map(() => ' '), '|', `${value.toFixed(2)}%`]
    console.log(array.join(''));
}

module.exports = {
    logPercent
}