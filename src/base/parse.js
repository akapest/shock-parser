import _ from 'lodash'
import moment from 'moment'
import crypto from 'crypto'

function takeText($el){
    let text = $el.text()
    if (!text) return ''
    return text.trim()
}
function parseImages($, offset, portfolio) {
    let images = $('.search-content li').map((i, el) => { // todo error
        let source = $(el).find('img').attr('src')
        let link = $(el).find('a').attr('href')
        let id = crypto.createHash('md5').update(source).digest('hex')
        let position = offset * 100 + i + 1
        if (portfolio) {
            let portfolioId = portfolio.name
            let description = takeText($(el).find('.description'))
            return {id, source, link, portfolioId, description, position}
        } else {
            return {id, source, link, position}
        }
    }).toArray()
    return images
}
function parseTotal($){
    const text = $('.page-max').first().text()
    if (text) {
        let units, thousands;
        if (text.indexOf('.') >= 0){
            [thousands, units] = text.split('.')
        } else {
            thousands = '0'
            units = text
        }
        [thousands, units] = [parseInt(thousands), parseInt(units)]
        return thousands*1000 + units
    } else {
        // todo error
    }
}
export {takeText, parseImages, parseTotal}